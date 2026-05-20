# 🛡️ GL.iNet KMWAN Discord Guard

A lightweight, zero-dependency bash script for GL.iNet routers (OpenWrt) that monitors Multi-WAN failover events and sends instant Discord Push notifications. 

## 🚨 The Problem: Why `mwan3.user` doesn't work anymore
GL.iNet routers running firmware 4.x (like the Beryl AX / GL-MT3000) abandoned the standard OpenWrt `mwan3` implementation in favor of their proprietary Kernel Multi-WAN (`kmwan`). Because `kmwan` modifies the kernel routing table directly and bypasses standard hotplug triggers, traditional failover notification scripts (like `/etc/mwan3.user`) **are completely ignored**.

## 💡 The Solution
This script acts as a silent observer. It runs in the background (using `0.0%` CPU) and reads the system's active routing table every 5 seconds. 

If `kmwan` decides the internet is down (due to packet loss or a physical cable disconnect) and switches the route to a failover interface (e.g., Tethering/Cellular), this script catches the routing change and safely dispatches a Discord Webhook.

### ✨ Features
* **Zero Dependencies:** Written in pure `sh`. No heavy packages required. Uses built-in OpenWrt tools (`ip route` and `curl`).
* **Zero Flash Wear:** Keeps the network state in volatile RAM (`LAST_STATE`) instead of continuously writing to the router's flash memory.
* **Race-Condition Proof:** Includes an intelligent retry-loop. If the script tries to send a webhook exactly when the router drops the connection to switch to failover, it won't fail. It waits and retries until the new connection stabilizes.

---

## 🛠️ Installation

### 1. Connect to your Router via SSH
Open your terminal and connect to the router. *(Note: `192.168.8.1` is the default GL.iNet IP. Change it if your router uses a different address).*
```bash
ssh root@192.168.8.1

```

### 2. Create the Script

Open a text editor (like `vi` or `nano`) and create the script file:

```bash
vi /usr/bin/discord_guard.sh

```

Paste the code from the `discord_guard.sh` file in this repository.
**⚠️ Important:** Don't forget to replace `YOUR_DISCORD_WEBHOOK_URL_HERE` with your actual Discord Webhook URL inside the script!

### 3. Make it Executable

Apply the necessary permissions so the system can run the script:

```bash
chmod +x /usr/bin/discord_guard.sh

```

### 4. Enable Autostart

Inject the script into your router's startup routine so it survives reboots:

```bash
sed -i '/exit 0/i /usr/bin/discord_guard.sh &' /etc/rc.local

```

### 5. Start the Guard

Run the script in the background for the first time:

```bash
/usr/bin/discord_guard.sh &

```

---

## 🧪 How to Test It

You don't have to wait for a real outage or unplug any cables!

1. Go to your GL.iNet Web Admin Panel -> **Network** -> **Multi-WAN**.
2. Change the tracking IP from `1.1.1.1` to a dead IP (e.g., `10.255.255.255`).
3. Apply changes. `kmwan` will think your main connection is dead and switch to the failover interface.
4. You will receive a Discord notification in seconds!
5. *(Don't forget to change the tracking IP back to `1.1.1.1` when you're done).*

---

## 🗑️ Uninstallation

If you want to completely remove the script and revert to factory behavior, run these 3 commands via SSH:

```bash
kill $(ps | grep '[d]iscord_guard.sh' | awk '{print $1}')
rm /usr/bin/discord_guard.sh
sed -i '\#/usr/bin/discord_guard.sh &#d' /etc/rc.local

```

## 📝 License

Distributed under the MIT License. Feel free to use, modify, and distribute.

