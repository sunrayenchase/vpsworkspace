# 🌐 Secure VPS Workspace Stack

A lightweight, portable workspace featuring reverse proxy routing via Caddy with Layer 4 support, proxy infrastructure with 3x-ui, automated workspace backup generation with real-time offsite replication via Syncthing, and active intrusion prevention powered by a containerized Fail2Ban engine tracking host SSH authentication attempts.

---

## 🛠️ Prerequisites & Initial Setup

Before deploying the workspace stack, complete the following local environmental initialization steps on your bare-metal server instance:

### 1. Provision Host System Environment
Log in via your root account and establish a dedicated operational non-root system user mapped with User ID `1000` to prevent privilege execution conflicts, then install the Docker orchestration subsystem engine:
```bash
# Add a custom operational non-root user matching UID/GID 1000
sudo useradd -u 1000 -m -s /bin/bash vpsuser
sudo usermod -aG sudo vpsuser

# Update host system core package registries
sudo apt update && sudo apt upgrade -y

# Deploy Docker Compose system dependencies
sudo apt install docker-compose-v2 docker.exe-ce -y
```

### 2. Handle External Domain Configuration
*   Navigate to [duckdns.org](https://duckdns.org), authenticate via your provider token identifier, and register a free domain subkey slot (e.g., `sub.duckdns.org`).
*   Bind the target domain records to target your VPS host machine's external public static IPv4 address.

### 3. Establish Replicating Infrastructure
*   Ensure an external secondary system infrastructure machine (such as a home laboratory server, local computer, or secondary cloud instance) has an operational Syncthing node configured and waiting to receive the workspace automated `.backup/` cluster data replication stream.

---

## 📁 Directory Architecture

```text
docker-workspace/
├── .env                       # Local Environment Variables
├── docker-compose.yml         # Main Stack Orchestration File
├── Dockerfile.caddy           # Custom Caddy build (with DuckDNS plugin)
├── .backup/                   # Local backup output directory
├── 3x-ui/                     # 3x-ui persistent storage directory
│   ├── db/                    # Core Xray/3x-ui operational databases (x-ui.db)
│   └── cert/                  # Hardened SSL/TLS custom certificate storage
├── caddy/
│   ├── Caddyfile              # Core Layer 4 and HTTP routing rules
│   ├── config/                # Caddy internal system configs
│   └── data/                  # ACME certificates and storage
├── fail2ban/                  # Containerized intrusion prevention configuration
│   ├── filter.d/              # Custom regex rules (sshd.conf)
│   └── jail.d/                # Active monitoring profiles (jail.local)
└── bscript/
    ├── backup.sh              # Cron backup execution engine
    └── restore.sh             # Interactive disaster recovery script
```

---

## ⚙️ Prerequisites & Environment Setup (`.env`)

Create a `.env` file in the root workspace folder from your template example. Customize all required environment variables, making sure your system user IDs and domain routing parameters match your hosting environment before initialization.

---

## 🏗️ Caddy Engine Extensibility Architecture

The local web server infrastructure relies on a custom-compiled multi-stage container deployment layer rather than using the generic static Caddy binary distribution profile. 

It is natively generated and built using **`xcaddy`** to incorporate two specialized ecosystem components:
1.  **`://github.com`**: Leverages the DuckDNS API token sequence to perform automated ACME cryptographic wildcard SSL/TLS certificate handling validations via programmatic DNS-01 challenges.
2.  **`://github.com`**: Intercepts inbound connection streams on raw lower-level sockets before HTTP translation layers. It handles advanced multiplexing logic, permitting Postgres connection routing, raw TLS ALPN inspection tricks, and Proxy Protocol v2 handshakes alongside normal HTTP services. Learn more via the official [Caddy Layer 4 Repository Page](https://://github.com).

### ⏳ Build Overhead & Resource Requirements
Because compiling Go-based plugins from source is resource-intensive:
*   **Compilation Time:** On single-core or entry-level low-spec VPS configurations, compiling the custom Caddy binary can take anywhere from **5 to 10 minutes** to complete.
*   **Disk Space Cache Constraints:** The temporary build dependencies and compiler layers require approximately **~3 GiB of free disk space** to complete successfully.

If your host runs critically low on storage capacity following compilation, reclaim that wasted disk space instantly by manually dropping the compilation layer records:
```bash
docker builder prune -a -f
```

---

## 🚀 Deployment Instructions

### 1. Configure System Execution Permissions
Grant execution capabilities to the internal workspace utility scripts on your host machine:
```bash
chmod +x bscript/backup.sh bscript/restore.sh
chmod -R 644 ./fail2ban/jail.d/* ./fail2ban/filter.d/*
```

### 2. Build and Boot the Services Stack
Compile the custom Caddy wrapper container image and deploy the entire architecture in the background:
```bash
docker compose up -d --build
```

---

## 🐋 Practical Docker Operations Cheat Sheet

Always execute these orchestration commands directly from within your main root `docker-workspace/` directory:

*   **Complete Rebuild and Relaunch**: Clears old layers, completely re-compiles Caddy plugins cache, and starts all system assets:
    ```bash
    docker compose down && docker compose up -d
    ```
*   **Fast Restart Without Rebuilding**: Safely loops the stack using the local image database without spending performance overhead running compile checkers:
    ```bash
    docker compose down && docker compose up -d --no-build
    ```
*   **Targeted Individual Service Restart**: Bypasses cycling the full workspace network chain when debugging a single node instance (e.g., `caddy`, `3x-ui`):
    ```bash
    docker compose restart [SERVICE_NAME]
    ```
*   **Real-Time Active Log Streaming**: Tracks operational system outputs and standard out error diagnostics logs interactively:
    ```bash
    docker compose logs -f [SERVICE_NAME]
    ```

---

## 🖥️ Web Panel Graphical User Interfaces (GUIs)

Once deployed, all administrative configurations are fully handled via web browsers using the following domain endpoints:

### 1. 3x-ui Panel Access
The proxy infrastructure console is accessible directly at your specialized subdomain URL:
```text
https://${XUI_WEB}.${DUCKDNSDOMAIN}/${XUI_SECRET_PATH}/
```
*   **Security Note:** On your very first login, secure this pane immediately by changing your admin credentials in the panel panel setting configurations.

### 2. Syncthing Dashboard Access & Pairing
All cross-machine replication links, connection pairings, and cluster synchronization settings are handled within the Syncthing Web UI. Access it at:
```text
https://${SYNC_WEB}.{DUCKDNSDOMAIN}/${SYNC_SECRET_PATH}/
```
*   **⚠️ Mandatory trailing slash:** You must append the final `/` to your secret path in the URL string, or asset paths will return a 404 block.
*   **First-Time Authentication Setup:** Syncthing will launch showing an initialization danger notification flag. Click **Actions -> Settings -> GUI** right away to enforce a strong administrative **Username** and **Password** barrier on top of your URL path block.

---

## 📦 Migrating Existing 3x-ui Configuration Data

If you are moving an existing standalone instance or an older 3x-ui installation onto this stack, you can migrate your operational states seamlessly before starting up the services:

1. **Database Migration**: Drop your existing `x-ui.db` file directly into the local `./3x-ui/db/` subdirectory.
2. **Certificate Migration**: Place any pre-generated custom encryption profiles (`.crt`, `.key`, `.pem` files) directly inside the `./3x-ui/cert/` folder.
3. **Permissions Sync**: Ensure the newly dropped items match your system host identifier so the container engine does not hit execution locks:
   ```bash
   chown -R 1000:1000 ./3x-ui
   ```

When the `3x-ui` container starts up, it will automatically detect and mount these database and certificate directories, preserving your configurations, users, and inbounds.

### 🔑 Emergency 3x-ui Web Path Recovery (SQL)
If you misplace, forget, or accidentally lock yourself out of your custom 3x-ui web panel routing subpath, you can reset it instantly back to the root (`/`) directory by injecting a direct SQLite modification command line utility straight into the container:
```bash
docker exec -it 3x-ui sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webMainPath';"
```

Once the database updates, restart the service container to clear its internal system configurations cache:
```bash
docker compose restart 3x-ui
```
*Your panel is now immediately accessible over your plain root subdomain link: `https://${XUI_WEB}.${DUCKDNSDOMAIN}`.*

---

## 🛡️ Security, Intrusion Prevention & Known Issues

*   **Non-Root Execution**: Caddy and Syncthing drop container privileges immediately upon launch via the native `user: "1000:1000"` directive to minimize host vulnerability vectors.
*   **Network Isolation**: Syncthing port `${SYNC_PANEL_PORT}` is not exposed to the public internet interface. It can only be interfaced through Caddy's internal software bridge network (`server_network`).
*   **Url Obfuscation Path Routing**: Standard scans to your root domains automatically return a dummy `404 Not Found` response. Access to the Syncthing console requires matching the hidden token variable path: `https://${SYNC_WEB}.${DUCKDNSDOMAIN}/${SYNC_SECRET_PATH}/`.
*   **Asymmetric Active Dual-Firewall Setup (Fail2Ban)**: Defensive perimeter controls are handled asymmetrically across two distinct runtime zones:
    1.  **Docker Interface Zone**: A containerized Fail2Ban wrapper container interfaces natively with the host network space (`network_mode: host`) running specific polling rules targeting `/var/log/auth.log` to filter and drop brute-force **Host SSH entry attempts** after 5 failure strikes.
    2.  **Application Internal Zone**: The `3x-ui` service leverages its own native internal built-in Fail2Ban module to protect its inbound transport networks directly inside its container logic boundaries.

### ⚠️ Critical Security Caveats & Blindspots
*   **No Web Panel Brute-Force Monitoring**: The containerized host-level Fail2Ban jail protects *strictly* the server's OpenSSH terminal port. It **does not** read web layer traffic logs.
*   **Web Console Exposure Alert**: If a malicious party uncovers your hidden obfuscation URL path arrays (`XUI_SECRET_PATH` or `SYNC_SECRET_PATH`), **neither the 3x-ui panel nor the Syncthing management dashboards are protected against password brute-forcing attacks.** You must manually set exceptionally strong, complex administrative passwords within those interfaces to block infiltration attempts.

### 📊 Fail2Ban Operations & Auditing Commands

Inspect active jail statuses and count active target blocks on your SSH interface:
```bash
docker compose exec fail2ban fail2ban-client status sshd
```

Review live container runtime filtering events:
```bash
docker compose logs -f fail2ban
```

Safely lift an accidental administrative lockout ban from your host IP address:
```bash
docker compose exec fail2ban fail2ban-client set sshd unbanip YOUR_IP_ADDRESS
```

---

## 🛠️ Backup Management & Recovery

### Run a Forced Backup Manual Execution
To capture a point-in-time checkpoint snapshot immediately before running host updates (`--force` or `-f`):
```bash
docker exec -it backup /bin/bash /workspace/bscript/backup.sh --force
```

### ⚡ Recovery Restoration Workflow (never tested)
If your primary host suffers structural failure or database corruption:

1. **Deploy Bare Stack**: Restore the raw directory structural layouts alongside your custom `.env` parameters file and fire up the cluster core using the fast zero-build flag:
   ```bash
   docker compose up -d --no-build
   ```
2. **Synchronize Local State**: Wait for Syncthing to automatically synchronize existing `.tar.gz` package assets from your secondary remote storage node into your host local space.
3. **Execute Extraction Prompts**:
   ```bash
   docker exec -it backup /bin/bash /workspace/bscript/restore.sh
   ```
4. **Deploy Target Point**: Input the item number of your selection checkpoint file, type `yes` to confirm clearing the active state contents, and allow extraction processing to finalize.
5. **Relaunch Stack**: Rebuild and boot all restored operational service dependencies:
   ```bash
   docker compose up -d --build
   ```
