#!/usr/bin/env bash
# Brave CPU Monitor - Helps identify problematic tabs/sites
# Usage: ./brave-cpu-monitor.sh

echo "🔍 Brave CPU Monitor"
echo "===================="
echo "This will monitor Brave processes every 2 seconds."
echo "Watch for CPU spikes and note what tab/site you were on."
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    clear
    echo "🔍 Brave CPU Monitor - $(date '+%H:%M:%S')"
    echo "=================================================="
    
    # Get top Brave processes
    BRAVE_PROCS=$(ps aux | grep '[b]rave' | wc -l)
    
    if [ "$BRAVE_PROCS" -eq 0 ]; then
        echo "❌ No Brave processes running"
    else
        echo "✅ Brave processes: $BRAVE_PROCS"
        echo ""
        echo "Top 5 Brave processes by CPU:"
        echo "------------------------------"
        ps aux | grep '[b]rave' | sort -k3 -rn | head -5 | awk '{printf "PID: %-7s CPU: %5s%% MEM: %5s%% TIME: %8s\n", $2, $3, $4, $10}'
        
        echo ""
        echo "⚠️  High CPU processes (>50%):"
        echo "------------------------------"
        HIGH_CPU=$(ps aux | grep '[b]rave' | awk '$3 > 50 {print}')
        if [ -z "$HIGH_CPU" ]; then
            echo "✅ None - all processes running normally"
        else
            echo "$HIGH_CPU" | awk '{printf "🔴 PID: %-7s CPU: %5s%% - Running for %s\n", $2, $3, $10}'
            echo ""
            echo "💡 TIP: If a process stays at 100% CPU:"
            echo "   1. Press Shift+Esc in Brave to open Task Manager"
            echo "   2. Identify the tab with high CPU usage"
            echo "   3. Note the website/extension"
            echo "   4. Kill the process: kill -9 <PID>"
        fi
    fi
    
    sleep 2
done
