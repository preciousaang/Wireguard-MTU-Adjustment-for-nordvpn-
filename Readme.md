````markdown
# nordlynx-mtu-fix

A simple utility that permanently fixes the **NordVPN (NordLynx/WireGuard) MTU fragmentation** and **connection drop** issue on Linux.

---

## The Problem

The NordVPN Linux daemon automatically sets the **`nordlynx`** interface MTU to **1420** every time a VPN connection is established.

On many networks, especially:

- PPPoE broadband
- Fiber connections
- 4G/5G mobile hotspots
- Some ISP networks

…the actual path MTU is lower than 1420.

When this happens, oversized packets are silently dropped, leading to symptoms such as:

- Hanging or partially loading web pages
- Random connection timeouts
- Downloads stalling
- Unstable VPN performance
- Complete loss of connectivity despite appearing "connected"

Unfortunately, simply changing the MTU manually does **not** solve the problem.

NordVPN recreates and reconfigures the `nordlynx` interface during every connection, overwriting any manual MTU changes.

Even standard **udev** rules usually fail because of a race condition, the rule executes before the NordVPN daemon finishes configuring the interface.

---

## The Solution

This project installs a **persistent delayed udev rule**.

Whenever the `nordlynx` interface is created, the rule:

1. Detects the new interface.
2. Launches a background helper.
3. Waits **2 seconds** for NordVPN to finish its configuration.
4. Applies your preferred MTU permanently for that connection.

This completely avoids the race condition while requiring no manual intervention after installation.

---

## Features

- ✔ Permanent MTU fix
- ✔ Survives every VPN reconnect
- ✔ No systemd services required
- ✔ Works automatically after installation
- ✔ Lightweight udev-based solution
- ✔ Custom MTU supported

---

# Installation

Clone the repository:

```bash
git clone https://github.com/<your-username>/nordlynx-mtu-fix.git
cd nordlynx-mtu-fix
```
````

Make the installer executable:

```bash
chmod +x setup-vpn-mtu.sh
```

Run it as root:

```bash
sudo ./setup-vpn-mtu.sh
```

By default, the script installs an MTU of **1400**.

---

# Testing

Disconnect and reconnect NordVPN:

```bash
nordvpn d
nordvpn c
```

Verify the MTU:

```bash
ip link show dev nordlynx
```

Expected output:

```text
mtu 1400
```

instead of

```text
mtu 1420
```

---

# Using a Custom MTU

You can specify any MTU value during installation.

For example, to use the universally safe minimum MTU of **1280**:

```bash
sudo ./setup-vpn-mtu.sh 1280
```

Example using **1380**:

```bash
sudo ./setup-vpn-mtu.sh 1380
```

---

# What the Script Does

The installer performs the following steps automatically:

- Verifies it is running as **root**
- Creates the helper script:

```text
/usr/local/bin/fix-nord-mtu.sh
```

- Installs the udev rule:

```text
/etc/udev/rules.d/99-nordlynx-mtu.rules
```

- Reloads udev rules
- Triggers udev so the fix works immediately
- No reboot required

---

# Why the Delay?

The NordVPN daemon configures the `nordlynx` interface **after** it is created.

Without a delay, any MTU changes are immediately overwritten.

Waiting two seconds ensures the daemon has finished before applying the MTU, making the change persistent for every VPN session.

---

# Recommended MTU Values

| Network Type              | Recommended MTU |
| ------------------------- | --------------: |
| Standard Ethernet         |            1400 |
| PPPoE                     |            1400 |
| Fiber                     |            1400 |
| LTE / 5G Hotspot          |       1280–1380 |
| Very restrictive networks |            1280 |

---

# Requirements

- Linux
- NordVPN Linux client
- Root privileges
- udev
- iproute2

---

# License

This project is released under the MIT License.

```

```
