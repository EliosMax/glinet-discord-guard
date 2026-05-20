#!/bin/sh

    # ==========================================
    # CONFIGURATION
    # ==========================================
    WEBHOOK_URL="YOUR_DISCORD_WEBHOOK_URL_HERE"

    # Default WAN interface (GL-MT3000 uses eth0 for WAN port)
    PRIMARY_IF="eth0"

    # Notification Messages
    MSG_DISCONNECTED="🔴 **WAN Down!** KMWAN switched the route (Main WAN offline)."
    MSG_CONNECTED="🟢 **WAN Restored!** Traffic is back on the main interface (WAN online)."

    # ==========================================
    # SCRIPT LOGIC
    # ==========================================
    LAST_STATE="unknown"

    send_msg() {
        local message="$1"
        
        # Wait for the router to stabilize the failover connection
        sleep 6 
        
        # Retry loop to prevent losing messages during active network switching
        for i in 1 2 3 4; do
            if curl -4 -s -m 15 -H "Content-Type: application/json" -d "{\"content\": \"$message\"}" "$WEBHOOK_URL"; then
                break
            fi
            sleep 4
        done
    }

    while true; do
        # Check the routing table to see which interface routes the default traffic
        CURRENT_GW=$(ip -4 route show default | grep default | awk '{print $5}' | head -n 1)

        if [ "$CURRENT_GW" = "$PRIMARY_IF" ]; then
            CURRENT_STATE="connected"
        else
            CURRENT_STATE="disconnected"
        fi

        if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
            if [ "$LAST_STATE" != "unknown" ]; then
                if [ "$CURRENT_STATE" = "disconnected" ]; then
                    send_msg "$MSG_DISCONNECTED"
                elif [ "$CURRENT_STATE" = "connected" ]; then
                    send_msg "$MSG_CONNECTED"
                fi
            fi
            LAST_STATE="$CURRENT_STATE"
        fi
        
        sleep 5
    done
