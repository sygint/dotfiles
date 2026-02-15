# AI Services Module for Cortex
# Provides Ollama (LLM backend) and Open WebUI (web interface)
# Optimized for NVIDIA RTX 5090 Suprim OC Liquid
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.features.ai-services;
in
{
  options.modules.features.ai-services = {
    enable = lib.mkEnableOption "AI services with Ollama and NVIDIA CUDA support";
    enableOllmcp = lib.mkEnableOption "Enable ollmcp for MCP tool support (filesystem, git, web search)";
    enableWebSearch = lib.mkEnableOption "Enable self-hosted web search via SearXNG" // {
      default = true;
    };
    enableOpenWebui = lib.mkEnableOption "Enable Open WebUI" // {
      default = true;
    };
    enableGpuFanControl =
      lib.mkEnableOption "Enable GPU fan control via nvidia-settings (for AIO coolers)"
      // {
        default = false;
      };
    gpuFanSpeed = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "GPU fan speed percentage when fan control is enabled";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable GPU driver userspace libraries (creates /run/opengl-driver/lib)
    # CRITICAL: Without this, libcuda.so.1 is not discoverable and Ollama
    # falls back to CPU-only inference with zero GPU utilization.
    hardware.graphics.enable = true;

    # Enable NVIDIA drivers for RTX 5090
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # CRITICAL: RTX 5090 (Blackwell) REQUIRES open kernel modules
      # Proprietary driver will fail with "requires use of the NVIDIA open kernel modules"
      open = true; # MUST be true for RTX 5090/Blackwell architecture

      # Enable modesetting (required for Wayland, useful even on headless)
      modesetting.enable = true;

      # Power management (important for high-end GPUs)
      powerManagement.enable = true;

      # Use the latest stable driver
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Enable NVIDIA persistence daemon for better performance
    hardware.nvidia.nvidiaPersistenced = true;

    # Set coolbits to enable fan control via nvidia-settings
    # coolbits: 4 = thermal control, 8 = fan speed control
    boot.extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
      options nvidia "coolbits=12"
      options nvidia_uvm uvm_disable_hmm=1
    '';

    # Xvfb for headless nvidia-settings (for GPU fan control on AIO coolers)
    systemd.services.xvfb = lib.mkIf cfg.enableGpuFanControl {
      description = "Xvfb virtual framebuffer for headless NVIDIA settings";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.xvfb}/bin/Xvfb :0 -screen 0 1920x1080x24";
      };
    };

    # GPU fan control service
    systemd.services.gpu-fan-control = lib.mkIf cfg.enableGpuFanControl {
      description = "NVIDIA GPU fan control via nvidia-settings";
      after = [ "xvfb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScriptBin "gpu-fan-control" ''
          # Wait for Xvfb to start
          sleep 2
          # Enable fan control
          nvidia-settings -a "GPUFanControlState=1" -a "FanSpeedPWM=${toString cfg.gpuFanSpeed}"
        ''}/bin/gpu-fan-control";
      };
    };

    # Enable Ollama LLM service with CUDA acceleration
    services.ollama = {
      enable = true;
      # Enable CUDA acceleration for RTX 5090
      package = pkgs.ollama-cuda;
      # Listen on all interfaces so we can access from other machines on the network
      host = "0.0.0.0";
      port = 11434;

      # Environment variables for optimal GPU performance
      environmentVariables = {
        # Allow Ollama to use most available VRAM (RTX 5090 has 32GB)
        # Leave ~2GB for display/system overhead
        OLLAMA_MAX_VRAM = "30000000000"; # 30GB
        # Enable CUDA graphs for better performance
        CUDA_LAUNCH_BLOCKING = "0";
      };

      # Preload models optimized for RTX 5090 (32GB VRAM)
      # NOTE: Only models that fit entirely in VRAM for best performance
      # Avoided 70B+ models which require RAM offloading (too slow)
      loadModels = [
        "llama3.2:3b" # Llama 3.2 3B - Ultra-fast baseline (~2GB VRAM)
        "qwen2.5:7b" # Qwen 2.5 7B - Excellent general purpose (~4GB VRAM)
        "deepseek-r1:14b" # DeepSeek R1 14B - Strong reasoning (~8GB VRAM)
        "qwen2.5-coder:32b" # Qwen 2.5 Coder 32B - Best coding model (~17GB VRAM)
        "command-r:35b" # Command-R 35B - Excellent for RAG/long context (~19GB VRAM)
        "mixtral:8x7b" # Mixtral 8x7B - MoE architecture, great performance (~26GB VRAM)
      ];
    };

    # Enable Open WebUI (formerly Ollama WebUI)
    # Note: Using port 8888 to avoid conflict with SearXNG on 8080
    services.open-webui = lib.mkIf cfg.enableOpenWebui {
      enable = true;
      host = "0.0.0.0";
      port = 8888;
      environment = {
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        WEBUI_AUTH = "true";
        WEBUI_NAME = "Cortex AI - RTX 5090";
        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "false";
      };
    };

    # Enable SearXNG - self-hosted metasearch engine for web search
    # Only accessible locally (127.0.0.1) for MCP tools to use
    services.searx = lib.mkIf cfg.enableWebSearch {
      enable = true;
      settings = {
        server = {
          bind_address = "127.0.0.1";
          port = 8080;
          secret_key = "localhost-only-search";
        };
        search = {
          formats = [
            "html"
            "json"
          ];
        };
        engines = [
          { name = "duckduckgo"; }
          { name = "google"; }
          { name = "bing"; }
          { name = "wikipedia"; }
        ];
      };
    };

    # Open firewall ports for AI services
    # Note: These are restricted by the main firewall config to local network only
    networking.firewall.allowedTCPPorts = [
      11434 # Ollama API
    ]
    ++ lib.optionals cfg.enableOpenWebui [
      8888 # Open WebUI
    ];

    # Ensure sufficient resources for AI workloads
    # Add some system tuning for better performance with large models
    boot.kernel.sysctl = {
      # Increase shared memory for larger models
      "kernel.shmmax" = 34359738368; # 32GB (match GPU VRAM)
      "kernel.shmall" = 8388608; # 32GB in pages
      # Optimize for high-throughput workloads
      "vm.swappiness" = 10; # Reduce swapping (we have plenty of RAM for models)
    };

    # Add useful packages for AI/ML administration
    # Includes optional ollmcp deps if enabled
    environment.systemPackages =
      (with pkgs; [
        ollama
        nvtopPackages.full
        cudaPackages.cudatoolkit
      ])
      ++ lib.optionals cfg.enableOllmcp (
        with pkgs;
        [
          uv
          nodejs
          git
          (python3.withPackages (
            ps: with ps; [
              ollama
            ]
          ))
        ]
      );

    # ollmcp configuration - MCP client for Ollama with tool support
    # This enables filesystem, git, and web search capabilities
    environment.etc."ollmcp/servers.json" = lib.mkIf cfg.enableOllmcp {
      text =
        let
          baseServers = {
            filesystem = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-filesystem"
                "/home/jarvis"
              ];
            };
          };
          webSearchServer = lib.optionalAttrs cfg.enableWebSearch {
            web-search = {
              command = "npx";
              args = [
                "-y"
                "@iflow-mcp/one-search-mcp"
              ];
              env = {
                SEARCH_PROVIDER = "searxng";
                SEARXNG_URL = "http://127.0.0.1:8080";
              };
            };
          };
        in
        builtins.toJSON (baseServers // webSearchServer);
    };

    # Systemd service overrides for better resource management
    systemd.services.ollama = {
      serviceConfig = {
        # Nice level for prioritization
        Nice = -10; # Higher priority for LLM inference
        # Limit memory usage to prevent OOM
        MemoryMax = "80%"; # Use up to 80% of system RAM
        # CPU affinity - use all cores
        CPUWeight = 100;
      };
    };
  };
}
