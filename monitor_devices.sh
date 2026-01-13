#!/bin/bash

echo "📱 iPhone Device Monitor"
echo "========================"
echo ""
echo "This script will continuously monitor for iPhone devices."
echo "Keep this running while you unplug/replug your iPhone."
echo ""
echo "Press Ctrl+C to stop"
echo ""

while true; do
    echo "--- $(date +"%H:%M:%S") ---"
    
    # Use system_profiler to check devices
    devices=$(system_profiler SPCameraDataType 2>/dev/null | grep -A 3 "iPhone")
    
    if [ -z "$devices" ]; then
        echo "❌ No iPhone devices found"
    else
        echo "$devices" | while read line; do
            if [[ "$line" == *"iPhone"* ]]; then
                if [[ "$line" == *"Camera"* ]]; then
                    echo "📷 CAMERA: $line"
                else
                    echo "📺 SCREEN: $line"
                fi
            elif [[ "$line" == *"Model ID"* ]] || [[ "$line" == *"Unique ID"* ]]; then
                echo "   $line"
            fi
        done
    fi
    
    echo ""
    sleep 2
done
