# AI Services Module for Cortex
# Provides Ollama (LLM backend) and Open WebUI (web interface)
# Optimized for NVIDIA RTX 5090 Suprim OC Liquid
{ config, lib, pkgs, ... }:

{
  # Enable NVIDIA drivers for RTX 5090
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.nvidia = {
    # Enable the proprietary NVIDIA driver
    open = false;  # Use proprietary driver for best compatibility with RTX 5090
    
    # Enable modesetting (required for Wayland, useful even on headless)
    modesetting.enable = true;
    
    # Power management (important for high-end GPUs)
    powerManagement.enable = true;
    
    # Use the latest stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable NVIDIA persistence daemon for better performance
  hardware.nvidia.nvidiaPersistenced = true;

  # CRITICAL: Workaround for RTX 5090 (Blackwell architecture) driver bug
  # Without this, CUDA will fail to initialize with "init failure: 3"
  # See: https://github.com/ollama/ollama/issues/11593
  # See: https://forums.developer.nvidia.com/t/solved-cuda-driver-initialization-failed-2x-rtx-5090/334578/4
  boot.extraModprobeConfig = ''
    options nvidia_uvm uvm_disable_hmm=1
  '';

  # Enable Ollama LLM service with CUDA acceleration
  services.ollama = {
    enable = true;
    # Enable CUDA acceleration for NVIDIA RTX 5090
    acceleration = "cuda";
    # Listen on all interfaces so we can access from other machines on the network
    host = "0.0.0.0";
    port = 11434;
    
    # Environment variables for CUDA optimization
    environmentVariables = {
      # Allow Ollama to use all available VRAM (RTX 5090 has 32GB)
      OLLAMA_MAX_VRAM = "30000000000";  # 30GB, leave 2GB for system
      # Enable CUDA graphs for better performance
      CUDA_LAUNCH_BLOCKING = "0";
    };
    
    # Preload models - with RTX 5090's 32GB VRAM, we can run large models!
    loadModels = [
      "llama3.2:3b"        # Llama 3.2 3B - Fast baseline for quick tasks
      "qwen2.5:7b"         # Qwen 2.5 7B - Excellent general purpose
      "deepseek-r1:14b"    # DeepSeek R1 14B - Strong reasoning capabilities
      "llama3.1:70b"       # Llama 3.1 70B - State-of-the-art quality (uses ~40GB with quantization, fits in VRAM+RAM)
      # Additional models to consider:
      # "qwen2.5-coder:32b" # Specialized coding model
      # "command-r:35b"     # Excellent for RAG and long context
      # "deepseek-r1:70b"   # Best-in-class reasoning (requires more memory)
    ];
  };

  # Enable Open WebUI (formerly Ollama WebUI)
  services.open-webui = {
    enable = true;
    # Port for web interface
    port = 8080;
    # Point to local Ollama instance
    environment = {
      OLLAMA_API_BASE_URL = "http://localhost:11434";
      # Enable various features
      WEBUI_AUTH = "true";  # Enable authentication
      WEBUI_NAME = "Cortex AI - RTX 5090";  # Custom branding
      # Allow file uploads for RAG (Retrieval Augmented Generation)
      ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "false";
    };
  };

  # Open firewall ports for AI services
  # Note: These are restricted by the main firewall config to local network only
  networking.firewall.allowedTCPPorts = [
    11434  # Ollama API
    8080   # Open WebUI
  ];

  # Ensure sufficient resources for AI workloads
  # Add some system tuning for better performance with large models
  boot.kernel.sysctl = {
    # Increase shared memory for larger models
    "kernel.shmmax" = 34359738368;  # 32GB (match GPU VRAM)
    "kernel.shmall" = 8388608;      # 32GB in pages
    # Optimize for high-throughput workloads
    "vm.swappiness" = 10;           # Reduce swapping (we have plenty of RAM for models)
  };

  # Add useful packages for AI/ML administration
  environment.systemPackages = with pkgs; [
    ollama           # CLI for managing models
    nvtopPackages.full  # NVIDIA GPU monitoring (like htop for GPU)
    cudaPackages.cudatoolkit  # CUDA toolkit for diagnostics
  ];

  # Systemd service overrides for better resource management
  systemd.services.ollama = {
    serviceConfig = {
      # Nice level for prioritization
      Nice = -10;  # Higher priority for LLM inference
      # Limit memory usage to prevent OOM
      MemoryMax = "80%";  # Use up to 80% of system RAM
      # CPU affinity - use all cores
      CPUWeight = 100;
    };
  };
}
