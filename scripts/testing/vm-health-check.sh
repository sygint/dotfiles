#!/usr/bin/env bash
# Quick health check script for NixOS VMs
# Run this inside the VM after login

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NixOS VM Health Check                      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo

# 1. System Info
echo -e "${BLUE}📊 System Information${NC}"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Kernel: $(uname -r)"
echo

# 2. Disk Space
echo -e "${BLUE}💾 Disk Space${NC}"
df -h / | tail -n 1
echo

# 3. Failed Services
echo -e "${BLUE}🔍 Checking for Failed Services${NC}"
FAILED=$(systemctl --failed --no-pager --no-legend | wc -l)
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ No failed services${NC}"
else
    echo -e "${RED}❌ $FAILED failed service(s):${NC}"
    systemctl --failed --no-pager
fi
echo

# 4. Network
echo -e "${BLUE}🌐 Network Configuration${NC}"
IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "N/A")
echo "IP Address: $IP"
echo

# 5. Service Status Check
echo -e "${BLUE}🔧 Service Status${NC}"

check_service() {
    local service=$1
    local port=$2
    local name=$3
    
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✅ $name${NC} - Running"
        if [ -n "$port" ]; then
            if ss -tlnp 2>/dev/null | grep -q ":$port "; then
                echo -e "   ${GREEN}├─ Port $port listening${NC}"
            else
                echo -e "   ${YELLOW}├─ Port $port NOT listening${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ $name${NC} - Failed/Inactive"
        if [ -n "$port" ]; then
            echo -e "   ${RED}├─ Port $port check skipped${NC}"
        fi
    fi
}

# Check common services based on what's installed
if systemctl list-unit-files | grep -q "jellyfin.service"; then
    check_service "jellyfin" "8096" "Jellyfin Media Server"
fi

if systemctl list-unit-files | grep -q "grafana.service"; then
    check_service "grafana" "3000" "Grafana"
fi

if systemctl list-unit-files | grep -q "prometheus.service"; then
    check_service "prometheus" "9090" "Prometheus"
fi

if systemctl list-unit-files | grep -q "prometheus-node-exporter.service"; then
    check_service "prometheus-node-exporter" "9100" "Node Exporter"
fi

if systemctl list-unit-files | grep -q "vikunja-api.service"; then
    check_service "vikunja-api" "3456" "Vikunja API"
fi

if systemctl list-unit-files | grep -q "vikunja-frontend.service"; then
    check_service "vikunja-frontend" "" "Vikunja Frontend"
fi

echo

# 6. Quick Service Tests
echo -e "${BLUE}🧪 HTTP Service Tests${NC}"

test_http() {
    local port=$1
    local name=$2
    local path="${3:-/}"
    
    if timeout 2 curl -sf "http://localhost:$port$path" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC} - Responding"
    elif timeout 2 curl -sI "http://localhost:$port$path" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC} - Responding (HEAD only)"
    else
        echo -e "${RED}❌ $name${NC} - Not responding"
    fi
}

# Test services if ports are listening
if ss -tlnp 2>/dev/null | grep -q ":3000 "; then
    test_http "3000" "Grafana"
fi

if ss -tlnp 2>/dev/null | grep -q ":3456 "; then
    test_http "3456" "Vikunja"
fi

if ss -tlnp 2>/dev/null | grep -q ":8096 "; then
    test_http "8096" "Jellyfin"
fi

if ss -tlnp 2>/dev/null | grep -q ":9090 "; then
    test_http "9090" "Prometheus" "/-/healthy"
fi

if ss -tlnp 2>/dev/null | grep -q ":9100 "; then
    test_http "9100" "Node Exporter" "/metrics"
fi

echo

# 7. Summary
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Health Check Complete                      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo
echo "Run 'journalctl -xe' to see recent logs"
echo "Run 'systemctl status <service>' for specific service details"
echo
