# AI Services on Cortex

## Overview

This document describes the AI/LLM infrastructure deployed on the `cortex` host, featuring local LLM inference powered by Ollama with NVIDIA RTX 5090 GPU acceleration.

## Hardware Specifications

- **GPU**: MSI NVIDIA RTX 5090 Suprim OC Liquid
  - Architecture: Blackwell (sm_120)
  - VRAM: 32GB GDDR7
  - Cooling: Liquid-cooled
- **Host**: cortex (192.168.1.7)

## Software Stack

### Core Components

1. **NVIDIA Driver**: Version 580.95.05
   - Type: Proprietary (stable)
   - Support: RTX 5090 Blackwell architecture
   - Workaround: HMM disabled (`uvm_disable_hmm=1`) for Blackwell stability

2. **CUDA Toolkit**: Version 12.8
   - Libraries: cuBLAS, cuFFT, cuRAND, cuSPARSE, cuSOLVER, nvcc, cupti
   - Full GPU acceleration stack for LLM inference

3. **Ollama**: Version 0.12.3
   - LLM inference engine
   - CUDA acceleration enabled
   - Network: Listening on `0.0.0.0:11434` (accessible from all hosts)
   - Storage: Models stored in `/var/lib/ollama`

4. **Monitoring Tools**:
   - `nvtop`: Real-time GPU monitoring (htop for NVIDIA GPUs)
   - `nvidia-smi`: NVIDIA GPU management interface

### Configuration Location

All AI services are configured in:
```
modules/system/ai-services/default.nix
```

Imported by:
```
systems/cortex/default.nix
```

## Preloaded Models

The following models are automatically downloaded on first boot:

| Model | Size | Parameters | Use Case |
|-------|------|------------|----------|
| `llama3.2:3b` | ~2GB | 3B | Fast inference, coding assistance, general chat |
| `qwen2.5:7b` | ~4GB | 7B | Advanced reasoning, multilingual support |
| `deepseek-r1:14b` | ~8GB | 14B | Deep reasoning, complex problem-solving |
| `llama3.1:70b` | ~40GB | 70B | Maximum quality, complex tasks, research |

**Total Storage Required**: ~54GB for all models

## Network Access

### Ollama API
- **URL**: `http://192.168.1.7:11434`
- **Access**: Available from all hosts on the network
- **Authentication**: None (internal network only)

### API Examples

**List models**:
```bash
curl http://192.168.1.7:11434/api/tags
```

**Generate completion**:
```bash
curl http://192.168.1.7:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Why is the sky blue?"
}'
```

**Chat completion**:
```bash
curl http://192.168.1.7:11434/api/chat -d '{
  "model": "qwen2.5:7b",
  "messages": [
    {"role": "user", "content": "Explain quantum computing"}
  ]
}'
```

### SSH Access

**Check GPU status**:
```bash
ssh jarvis@192.168.1.7 "nvidia-smi"
```

**Monitor GPU in real-time**:
```bash
ssh jarvis@192.168.1.7 "nvtop"
```

**Check Ollama status**:
```bash
ssh jarvis@192.168.1.7 "systemctl status ollama"
```

**List available models**:
```bash
ssh jarvis@192.168.1.7 "ollama list"
```

## CLI Usage

From any host in the network, you can use Ollama's CLI by setting the `OLLAMA_HOST` environment variable:

```bash
# Set the remote host
export OLLAMA_HOST=http://192.168.1.7:11434

# List models
ollama list

# Run a model interactively
ollama run llama3.2:3b

# Generate a single completion
ollama run qwen2.5:7b "Explain NixOS in simple terms"

# Pull new models
ollama pull mistral:7b
```

Or directly on cortex via SSH:
```bash
ssh jarvis@192.168.1.7 "ollama run llama3.2:3b 'Hello, world!'"
```

## GPU Optimization

The configuration includes several optimizations for the RTX 5090:

1. **Shared Memory**: 32GB allocated for large model contexts
2. **Blackwell Workaround**: HMM disabled for stability
   ```nix
   boot.extraModprobeConfig = "options nvidia_uvm uvm_disable_hmm=1";
   ```
3. **CUDA Acceleration**: Full CUDA 12.8 stack with optimized libraries
4. **Power Management**: NVIDIA Persistenced daemon for instant GPU wake

## Troubleshooting

### Check NVIDIA Driver Status
```bash
ssh jarvis@192.168.1.7 "nvidia-smi"
```

Expected output should show:
- Driver Version: 580.95.05
- CUDA Version: 12.8
- GPU: NVIDIA RTX 5090

### Check Ollama Service
```bash
ssh jarvis@192.168.1.7 "systemctl status ollama"
```

Should show `active (running)`.

### View Ollama Logs
```bash
ssh jarvis@192.168.1.7 "journalctl -u ollama -f"
```

### Test GPU Acceleration
```bash
# This should show CUDA libraries being used
ssh jarvis@192.168.1.7 "OLLAMA_DEBUG=1 ollama run llama3.2:3b 'test' 2>&1 | grep -i cuda"
```

### Common Issues

**Issue**: NVIDIA driver fails to load
- **Solution**: Check if HMM workaround is applied in kernel parameters
- **Command**: `ssh jarvis@192.168.1.7 "cat /proc/cmdline | grep uvm_disable_hmm"`

**Issue**: Ollama can't find CUDA libraries
- **Solution**: Verify CUDA environment variables
- **Command**: `ssh jarvis@192.168.1.7 "systemctl cat ollama | grep Environment"`

**Issue**: Model download fails
- **Solution**: Check disk space and network connectivity
- **Commands**: 
  ```bash
  ssh jarvis@192.168.1.7 "df -h /var/lib/ollama"
  ssh jarvis@192.168.1.7 "journalctl -u ollama-model-loader -f"
  ```

## Performance Monitoring

### Real-time GPU Monitoring
```bash
# Interactive GPU monitor (like htop)
ssh jarvis@192.168.1.7 "nvtop"

# Watch nvidia-smi every 2 seconds
ssh jarvis@192.168.1.7 "watch -n 2 nvidia-smi"
```

### Model Inference Metrics
```bash
# Check inference performance
ssh jarvis@192.168.1.7 "ollama run llama3.2:3b 'Count to 10' --verbose"
```

## Future Enhancements

### Planned Additions

1. **Open WebUI**: Web-based interface for Ollama
   - Status: Temporarily disabled due to ctranslate2 build issues
   - Alternative: Use Ollama CLI or third-party web UIs

2. **Additional Models**: Consider adding:
   - `codellama:34b` - Specialized coding model
   - `mixtral:8x7b` - Mixture of experts for versatility
   - `yi:34b` - High-quality general purpose model

3. **API Gateway**: Nginx reverse proxy with:
   - SSL/TLS termination
   - API key authentication
   - Rate limiting
   - Request logging

4. **Monitoring Dashboard**: Grafana + Prometheus for:
   - GPU utilization over time
   - Model inference latency
   - Request volume and patterns
   - VRAM usage tracking

### Model Management

**Pull new models**:
```bash
ssh jarvis@192.168.1.7 "ollama pull <model-name>"
```

**Remove unused models**:
```bash
ssh jarvis@192.168.1.7 "ollama rm <model-name>"
```

**Update existing models**:
```bash
ssh jarvis@192.168.1.7 "ollama pull <model-name>"
```

## Security Considerations

⚠️ **Important**: The Ollama API is currently exposed without authentication on the local network (`0.0.0.0:11434`).

### Current Security Posture
- ✅ Only accessible on local network (192.168.1.0/24)
- ✅ Firewall protects from external access
- ❌ No API authentication
- ❌ No rate limiting
- ❌ No audit logging

### Recommendations for Production Use

If exposing to untrusted networks:
1. Add authentication layer (API keys, OAuth)
2. Implement rate limiting to prevent abuse
3. Enable audit logging for all API requests
4. Use TLS/SSL for encrypted transport
5. Consider VPN or SSH tunneling for remote access

For internal network use, current setup is acceptable.

## Configuration Reference

### NixOS Module
```nix
# modules/system/ai-services/default.nix
{
  # Enable NVIDIA drivers
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;  # Use proprietary driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  # RTX 5090 Blackwell workaround
  boot.extraModprobeConfig = "options nvidia_uvm uvm_disable_hmm=1";
  
  # Ollama service
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    port = 11434;
  };
}
```

### System Packages
The following packages are installed system-wide on cortex:
- `ollama` - LLM inference engine
- `nvtop` - GPU monitoring
- `nvidia-settings` - NVIDIA configuration GUI
- Full CUDA toolkit (12.8)

## Deployment

This configuration is deployed via the fleet management system:

```bash
# Deploy from nixos directory
./scripts/fleet.sh deploy cortex

# Or rebuild directly on cortex
ssh jarvis@192.168.1.7 "sudo nixos-rebuild switch --flake /etc/nixos#cortex"
```

After deployment, cortex will:
1. Build NVIDIA drivers and CUDA libraries
2. Reboot to load kernel modules
3. Start Ollama service
4. Download all preloaded models (may take 15-45 minutes)

## Related Documentation

- [Fleet Management](FLEET-MANAGEMENT.md) - Deployment and centralized management
- [System Security](../../docs/SECURITY.md) - Security policies and configurations
- [Secrets Management](../../SECRETS.md) - Secure credential management

## References

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [NVIDIA RTX 5090 Specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)
- [CUDA 12.8 Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/)
- [NixOS NVIDIA Driver Configuration](https://nixos.wiki/wiki/Nvidia)
- [Blackwell HMM Workaround](https://github.com/NixOS/nixpkgs/issues/11593)

---

*Last Updated: October 19, 2025*
*Configuration Version: cortex-25.11.20251007.c9b6fb7*
