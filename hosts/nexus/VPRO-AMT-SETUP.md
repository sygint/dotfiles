# Intel vPro / AMT Setup Guide

## What is Intel vPro / AMT?

**Intel Active Management Technology (Intel AMT)** is part of Intel vPro, a built-in remote management system in modern Intel business-class PCs. Think of it as **hardware-level remote access** - you can manage systems even when:

- ❌ The OS is crashed or unbootable
- ❌ The system is powered off (but plugged in!)
- ❌ No SSH/network access from the OS
- ✅ **You have full KVM-over-IP access** (keyboard, video, mouse)
- ✅ **You can remote power on/off**
- ✅ **You can mount remote ISOs**
- ✅ **You can access BIOS remotely**

### Why Set This Up?

Modern Intel vPro systems (like HP EliteDesk, ThinkCentre, etc.) give you:

1. **Remote KVM** - See the screen, control keyboard/mouse via web browser
2. **Remote Power** - Power on/off from anywhere on your network
3. **Remote Boot Control** - Boot from PXE, ISO, change boot order
4. **Serial-over-LAN** - Console access even when SSH is down
5. **Hardware Monitoring** - Temperatures, fans, voltages
6. **Out-of-Band Management** - Works even when OS is dead

**It's like having a physical KVM switch and crash cart, but built into the hardware!**

## Supported Systems

**Intel vPro is available on:**
- HP EliteDesk, ProDesk, Z-series workstations
- Lenovo ThinkCentre, ThinkStation
- Dell OptiPlex, Precision workstations
- Intel NUC Pro models
- Most business-class Intel systems (6th gen Core and newer)

**Check if your system has vPro:**
```bash
# Check system info
sudo dmidecode -t system | grep -i "product\|version"

# Check for Intel AMT
sudo lshw -C network | grep -i AMT

# Look for "Intel vPro" sticker on the PC
```

**Your fleet:**
- **Nexus** (HP EliteDesk G4 800): ✅ Has vPro (8th gen Core)
- **Axon** (Future system): Check specs
- **Cortex** (AI server): Likely has vPro if business-class
- **Orion** (Framework laptop): ❌ No vPro (consumer laptop)

## Initial Setup: Enable AMT in BIOS

### Step 1: Enter Intel Management Engine BIOS Extension (MEBx)

**Access varies by manufacturer:**

**HP (EliteDesk, ProDesk):**
- Press **F9** during POST → Select "Intel Management Engine"
- Or press **Ctrl+P** when prompted
- Or F10 → Advanced → Intel vPro Setup

**Lenovo (ThinkCentre):**
- Press **F1** during POST → Config → Intel AMT

**Dell (OptiPlex):**
- Press **F2** during POST → Advanced → Intel AMT

**Intel NUC:**
- Press **F2** during POST → Advanced → Intel AMT Configuration

**Default MEBx password:** `admin`

### Step 2: Configure Intel AMT (Manual Provisioning)

Once in MEBx:

1. **Change default password** (REQUIRED!)
   - Current: `admin`
   - New: Use a strong password (8+ chars, upper, lower, number, special)
   - **Save this password!** You'll need it for web UI access

2. **Intel AMT Configuration:**
   - Select: **Intel AMT Configuration**
   - Enable: **Manageability Feature Selection** → **Enabled**
   - Select: **Activate Network Access** → **Yes**

3. **Network Setup:**
   - Select: **Network Setup**
   - Select: **Intel ME Network Name Settings**
   - Host Name: `your-hostname` (e.g., `nexus`, `axon`)
   - Domain Name: `home.local` (or your domain)

4. **User Consent:**
   - Select: **User Consent**
   - Options:
     - **None** - No consent required (full remote access)
     - **KVM Only** - Requires consent for KVM (recommended for homelab)
     - **All** - Requires consent for all operations
   - **Recommendation:** Set to **None** or **KVM Only**

5. **SOL (Serial-over-LAN):**
   - Should be **enabled** by default
   - If not: Enable it in **Intel AMT Configuration**

6. **Save and Exit**
   - Exit MEBx
   - System will reboot

### Step 3: Configure Network Settings

AMT uses the same network interface as the OS, but:
- It has its own IP configuration
- It works even when the OS is down
- Can share the IP with the OS or use a separate IP

**Option 1: Shared IP (Easier)**
- AMT and OS share the same IP address
- No extra network configuration needed
- Recommended for homelab

**Option 2: Separate IP**
- AMT gets its own IP (e.g., 192.168.1.X+100)
- OS uses primary IP
- Better for production/enterprise

**Configure in MEBx:**
1. **Network Setup** → **TCP/IP Settings**
2. **DHCP Mode:** Disabled (for static IP) or Enabled (for DHCP)
3. **IPv4 Configuration (if static):**
   - IP Address: Your chosen IP
   - Subnet Mask: `255.255.255.0` (or your subnet)
   - Gateway: Your router IP
   - DNS: Your DNS server or `8.8.8.8`

## Accessing Intel AMT

### Method 1: Web UI (Easiest!)

**Without TLS (Non-secure, OK for homelab):**
```
http://<your-ip>:16992
```

**With TLS (Secure, requires certificate setup):**
```
https://<your-hostname>:16993
```

**Login:**
- Username: `admin`
- Password: The MEBx password you set

**What you can do:**
- View system information (CPU, RAM, temps)
- Power control (on/off/reset)
- Boot options (PXE, ISO, USB)
- Remote desktop (KVM)
- Serial-over-LAN console

### Method 2: MeshCommander (Recommended!)

MeshCommander is an excellent open-source web-based tool for managing Intel AMT.

**Install MeshCommander:**
```bash
# On Orion or any machine
# Download from: https://meshcommander.com/meshcommander

# Or run it as a docker container
docker run -d -p 3000:3000 --name meshcommander \
  ghcr.io/ylianst/meshcommander:latest

# Access at: http://localhost:3000
```

**Add a system to MeshCommander:**
1. Open MeshCommander
2. Click **"Add Computer"**
3. Enter:
   - Name: System hostname (e.g., `Nexus`, `Axon`)
   - Host: `<ip-address>:16992`
   - Username: `admin`
   - Password: Your MEBx password
4. Click **"Connect"**

**Features in MeshCommander:**
- 📺 **Remote Desktop (KVM)** - Full screen control
- 🔌 **Power Control** - On/Off/Reset/Sleep
- 💿 **IDE-R/USB-R** - Mount remote ISOs
- ⚙️ **BIOS Access** - Change BIOS settings remotely
- 📊 **Hardware Info** - Real-time system stats
- 🖥️ **Serial Console** - SOL access

### Method 3: Command Line (amtterm/wsman)

**Install tools:**
```bash
# On your management machine (e.g., Orion)
nix-shell -p amtterm wsmancli

# Serial-over-LAN console
amtterm <target-ip>

# Power control
wsman invoke -a RequestPowerStateChange \
  http://intel.com/wbem/wscim/1/ips-schema/1/IPS_PowerManagementService?SystemCreationClassName=CIM_ComputerSystem,SystemName=Intel(r)AMT,CreationClassName=IPS_PowerManagementService,Name=Intel(r) \
  PowerState -J power.json -h <target-ip> -P 16992 -u admin -p <password>
```

## Advanced: Enable TLS (Optional but Recommended)

For secure access over the internet, you'll want TLS enabled.

**Requirements:**
- Domain name (e.g., nexus.yourdomain.com)
- Certificate from supported CA (Comodo, GoDaddy, DigiCert, etc.)
- Intel SCS (Setup and Configuration Software) or similar

**Process:**
1. Purchase/generate a certificate with CN matching your domain
2. Use Intel SCS or MeshCommander to upload the certificate
3. Enable TLS in AMT configuration
4. Access via `https://nexus.yourdomain.com:16993`

**For homelab:** Non-TLS mode is usually fine! Just make sure AMT isn't exposed to the internet.

## NixOS Integration

### Enable Intel MEI Driver

Include in your NixOS configuration:

```nix
# In hardware.nix
boot.initrd.availableKernelModules = [ 
  "mei_me"  # Intel Management Engine Interface
  # ... other modules
];

# Intel graphics (VAAPI) includes AMT support
hardware.opengl.extraPackages = with pkgs; [
  intel-media-driver  # Includes MEI/AMT support
];
```

### Check AMT Status from NixOS

```bash
# Check if MEI driver is loaded
lsmod | grep mei

# Check AMT version and status
sudo dmidecode -t 0

# Check network interface
ip addr show

# View AMT events
journalctl -u lms  # If Intel LMS service is installed
```

## Common Use Cases

### 1. Remote KVM Access

**Scenario:** System won't boot, need to see the screen

1. Open MeshCommander or AMT Web UI
2. Click **"Remote Desktop"** or **"KVM"**
3. View the screen, control with keyboard/mouse
4. Fix the boot issue, reboot

### 2. Remote Power On

**Scenario:** System is powered off, need to start it

```bash
# From management machine
wsman invoke -a RequestPowerStateChange \
  http://intel.com/wbem/wscim/1/ips-schema/1/IPS_PowerManagementService \
  -h <target-ip> -P 16992 -u admin -p <password> \
  -k PowerState=2  # 2 = Power On
```

Or use MeshCommander → Power Control → Power On

### 3. Remote ISO Mount

**Scenario:** Need to reinstall or boot from recovery ISO

1. MeshCommander → Remote Desktop
2. **IDE-R** tab → **Mount Image**
3. Select ISO file from your computer
4. Reboot the system
5. It boots from the mounted ISO!

### 4. Serial Console Access

**Scenario:** SSH is down, need console access

```bash
# From management machine
amtterm <target-ip>

# Login as configured user
# You now have a serial console!
```

### 5. Remote BIOS Configuration

**Scenario:** Need to change BIOS settings

1. Power on or reboot system via AMT
2. Open KVM in MeshCommander
3. Press appropriate key during boot to enter BIOS (F2/F10/Del/F1)
4. Make changes remotely!

## Troubleshooting

### "Can't access AMT web UI"

**Check if AMT is enabled:**
```bash
# From the target system
sudo lspci | grep -i management
# Should show: Intel Management Engine

# From management machine
ping <target-ip>
curl http://<target-ip>:16992
```

**Solutions:**
- Make sure you enabled "Network Access" in MEBx
- Check firewall isn't blocking ports 16992/16993
- Verify IP address is correct
- Try rebooting the system

### "Wrong password"

**Problem:** Can't login with MEBx password

**Solution:**
- Default is `admin` if never changed
- Reset in MEBx: Boot → Ctrl+P → Change password
- Password must be strong (8+ chars, mixed case, number, special)

### "KVM not working"

**Problem:** Can connect but KVM/remote desktop doesn't work

**Solution:**
- User Consent might be set to "All" - change to "None" in MEBx
- Make sure you're using a compatible browser (Chrome/Firefox)
- Try MeshCommander instead of web UI
- Check that VNC or KVM is enabled in AMT configuration

### "AMT disabled after power loss"

**Problem:** AMT doesn't work after unplugging

**Solution:**
- AMT requires standby power (5V standby from PSU)
- Make sure the power cable is connected
- Check PSU is working
- Some settings survive power loss, some don't - reconfigure if needed

## Security Considerations

### For Homelab:

✅ **Safe:**
- Use strong MEBx password
- Only enable AMT on LAN (not exposed to internet)
- Set User Consent to "KVM Only" for extra safety
- Non-TLS mode is OK for homelab

❌ **Avoid:**
- Default password (`admin`)
- Exposing AMT ports (16992/16993) to internet without TLS
- Disabling all User Consent without firewall rules

### For Production:

🔒 **Required:**
- TLS mode with valid certificate
- Strong passwords
- Firewall rules (only allow trusted IPs)
- VPN or SSH tunnel for remote access
- User Consent enabled
- Audit logging enabled

## Comparison: AMT vs. Other Solutions

| Feature | Intel AMT | iLO/iDRAC | gli.net KVM | Raspberry Pi KVM |
|---------|-----------|-----------|-------------|------------------|
| **Built-in** | ✅ Yes | ✅ Yes | ❌ External | ❌ External |
| **Cost** | ✅ Free | 💰 Expensive | 💰 $50-200 | 💰 $50-100 |
| **Power Control** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **KVM** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **ISO Mount** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Limited |
| **BIOS Access** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Power Off Access** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Extra Hardware** | ❌ No | ❌ No | ✅ Required | ✅ Required |
| **Setup Time** | ⚡ 10 min | ⚡ 5 min | 🕐 30 min | 🕐 1 hour |

**For your homelab:** If your systems have vPro, AMT is perfect! It's built-in, free, and works great.

## Resources

- [Intel AMT Documentation](https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/)
- [MeshCommander](https://meshcommander.com/meshcommander)
- [Intel vPro Overview](https://www.intel.com/content/www/us/en/architecture-and-technology/vpro/overview.html)

## Next Steps

1. ✅ **Check if your system has vPro** (see Supported Systems section)
2. ✅ **Enable AMT in MEBx** (see Initial Setup section)
3. ✅ **Test web UI access** at http://your-ip:16992
4. ✅ **Install MeshCommander** for easy management
5. ✅ **Test KVM** - Make sure remote desktop works
6. ✅ **Test power control** - Remote power on/off
7. 🎉 **Enjoy hassle-free remote management!**

**Pro Tip:** Even if you have physical KVM switches (like gli.net), AMT is great for day-to-day management. Keep both as backup options!
