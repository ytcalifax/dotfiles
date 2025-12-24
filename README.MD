# 🚀 Server Dotfiles

> **Automated infrastructure hardening, performance tuning, and shell customization for Linux servers.**

This repository provides a production-grade provisioning script to set up a secure, high-performance environment on Linux servers and Raspberry Pis. It applies sensible defaults, installs essential utilities, and configures system parameters for optimal performance.

## ✨ Features

- **⚡ Performance Tuning**: Applies kernel optimizations via `sysctl` and sets the `latency-performance` profile using `tuned`.
- **🛡️ Security Hardening**: Configures `firewalld` with SSH access and removes `ufw` to prevent conflicts.
- **🐚 Shell Experience**: Installs [Starship](https://starship.rs) for a minimal, fast prompt and [Fastfetch](https://github.com/fastfetch-cli/fastfetch) for system info.
- **📊 Monitoring**: Includes [btop](https://github.com/aristocratos/btop) for real-time resource monitoring.
- **🔧 Essential Tools**: Installs `tar`, `nano`, and `curl`.

## 📥 Installation

Run the following command to download and execute the setup script. This must be run as a regular user with `sudo` privileges.

```bash
bash <(curl -s https://bin.blockloom.ch/dotQO7Dg)
```

> **Note**: The script will automatically detect your OS, install dependencies, and apply configurations.

## 🐧 Supported Systems

The script supports the following Linux distributions:

| Family | Distributions | Versions |
|--------|---------------|----------|
| **Debian** | Ubuntu, Debian, Raspbian | 22+, 11+, 11+ |
| **RHEL** | CentOS, RHEL, AlmaLinux, Rocky, Oracle Linux | 8+ |
| **Fedora** | Fedora | All recent |

## ⚙️ Configuration Details

### 1. System Tuning (`sysctl`)
A comprehensive set of kernel parameters is applied to optimize networking, memory management, and filesystem performance.
- **File**: [`etc/sysctl.d/99-performance-tuning.conf`](etc/sysctl.d/99-performance-tuning.conf)
- **Key Optimizations**: Increased file descriptors, optimized TCP stack (congestion control, keepalives), and virtual memory tuning.

### 2. Shell Customization (`starship` & `bashrc`)
A minimal and fast configuration for the Starship prompt is installed, and the system-wide `bashrc` is enhanced.
- **Starship Config**: Fetched directly from this repository during installation.
- **Bashrc Enhancements**:
  - Initializes **Starship** prompt.
  - Runs **Fastfetch** on login for system overview.
  - Aliases `btop` to `sudo btop` for full metrics access.
  - Clears screen on login.

### 3. Firewall (`firewalld`)
`firewalld` is enabled as the default firewall manager.
- **Default Zone**: `public`
- **Allowed Services**: `ssh`
- **Action**: `ufw` is removed to ensure a single source of truth for firewall rules.

## 🤝 Contributing

Issues and pull requests are welcome! Please file an issue if you encounter any problems or have suggestions for improvements.

---
*Designed for Linux Servers & Raspberry Pis.*
