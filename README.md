# 🌐 VPS Tunnel Stack (3x-ui, Caddy, Fail2Ban, Syncthing)

Caddy reverse proxy to 3x-ui web-panel and Syncthing web-panel to avoid opening any ports except 22, 80 (tecnically not used) and 443. Fail2Ban for SSH. Syncthing to remotely upload backup snapshot.

---

## 🛠️ Prerequisites & Initial Setup

Before deploying the workspace stack, complete the following local environmental initialization steps on your VPS server instance:

### 1. Provision Host System Environment
Log in via your root account and establish a dedicated operational non-root system user mapped with User ID `1000` to prevent privilege execution conflicts, then install the Docker orchestration subsystem engine:
```bash
# Add a custom operational non-root user matching UID/GID 1000
sudo useradd -u 1000 -m -s /bin/bash vpsuser
sudo usermod -aG sudo vpsuser

# Set timezone
sudo timedatectl set-timezone Europe/Moscow

# Disable sudo password (optional)
sudo visudo
```

In the bottom of the file, add the following line: `vpsuser ALL=(ALL) NOPASSWD: ALL`

Add ssh certificates login for vpsuser:
```bash
# Relogin
su - vpsuser

# Add a ssh key login
mkdir ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste the public key there.

Update and install Midnight Commander:
```bash
# Update host system core package registries
sudo apt update && sudo apt upgrade -y

# Install Midnight Commander (optional)
sudo apt install mc
```

Set up Docker's apt repository:
```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```bash
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Add user to docker group (omit sudo for each docker compose):
```bash
sudo usermod -aG docker vpsuser
```

Verify that Docker is running:
```bash
sudo systemctl status docker
```

Remove Ubuntu login welcome message garbage (optional):
```bash
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news
sudo chmod -x /etc/update-motd.d/85-fwupd
sudo chmod -x /etc/update-motd.d/90-updates-available
sudo systemctl disable fwupd fwupd-refresh.timer
sudo systemctl stop fwupd
```

Set/change hostname (optional):
```bash
sudo hostnamectl set-hostname vps
```

Clone this repo:
```bash
mkdir ~/vps
git clone https://github.com/sunrayenchase/vpsworkspace ~/vps
```
---

## 📁 Directory Architecture

```text
vps/
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

### 2. Handle External Domain Configuration
*   Navigate to [duckdns.org](https://duckdns.org), authenticate via your provider token identifier, and register a free domain subkey slot (e.g., `sub.duckdns.org`).
*   Bind the target domain records to target your VPS host machine's external public static IPv4 & IPv6 addresses.

### 3. Establish Replicating Infrastructure
*   Ensure an external secondary system infrastructure machine (such as a home laboratory server, local computer, or secondary cloud instance) has an operational Syncthing node configured and waiting to receive the workspace automated `.backup/` cluster data replication stream.

---

## 🚀 Deployment Instructions

### 1. Prerequisites & Environment Setup (`.env`)
Create a `.env` file in the root workspace folder from your template example. Customize all required environment variables before initialization:
```bash
cp ~/vps/.env.example ~/vps/.env
nano ~/vps/.env
```

Use random strings for web URIs
```bash
tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 18
echo
```

### 2. Configure System Execution Permissions
Grant execution capabilities to the internal workspace utility scripts on your host machine:
```bash
chmod +x bscript/backup.sh bscript/restore.sh
chmod -R 644 ./fail2ban/jail.d/* ./fail2ban/filter.d/*
```

### 3. Build and Boot the Services Stack
Compile the custom Caddy wrapper container image and deploy the entire architecture in the background:
```bash
docker compose up -d --build
```

### ⏳ Custom Caddy build with duckdns and caddy-l4
Compiling Go-based plugins from source is resource-intensive:
*   **Compilation Time:** On single-core or entry-level low-spec VPS configurations, compiling the custom Caddy binary can take anywhere from **10 to 60 minutes** to complete.
*   **Disk Space Cache Constraints:** The temporary build dependencies and compiler layers require approximately **~3 GiB of free disk space** to complete successfully.

1.  **[github.com/caddy-dns/duckdns]https://github.com/caddy-dns/duckdns**: Leverages the DuckDNS API token sequence to perform automated ACME cryptographic wildcard SSL/TLS certificate handling validations via programmatic DNS-01 challenges.
2.  **[github.com/mholt/caddy-l4]https://github.com/mholt/caddy-l4**: Intercepts inbound connection streams on raw lower-level sockets before HTTP translation layers. It handles advanced multiplexing logic, permitting Postgres connection routing, raw TLS ALPN inspection tricks, and Proxy Protocol v2 handshakes alongside normal HTTP services. Learn more via the official (not user in the default configuration).


### 4. Enter the CLI 3x-ui settings to setup login and password for web-panel access
Compile the custom Caddy wrapper container image and deploy the entire architecture in the background (no need to setup SSL certificates - the latter warning in 3x-ui webpanel may be ignored):
```bash
docker exec -it 3x-ui x-ui
```

### 5. Enter 3x-ui web-panel for initial setup
The proxy infrastructure console is accessible directly at your specialized subdomain URL:
```text
https://${XUI_WEB}.${DUCKDNSDOMAIN}/${XUI_SECRET_PATH}/
```
*   **3x-ui mandatory inbound setting:** Inbound -> Basics -> Port must be set to `${XUI_INBOUND_PORT}` value from `.env` (ignore the panel warning); Inbound -> Stream -> Proxy must be checked (for caddy reverse proxy to work); for xray cores starting v26.9.x fingerpring must be set to Chrome [github.com/MHSanaei/3x-ui/issues/6568]https://github.com/MHSanaei/3x-ui/issues/6568.
*   **Outboung to WARP:** setup free WARP outbound and route all the outgoing traffic there by default as a safeguard from spoofing the VPS IP on outbound by a software on your client.
*   **Client setting:** 3x-ui automatically passes to clients configs the connection port set in the inbound settings, which must be changed to `443` manually. Connection server may be set to `${DUCKDNSDOMAIN}.duckdns.org` instead of the server IP.
*   **Sing-box core compatibility:** with clients on sing-box core change 3x-ui panel version to `3.7.0` in `docker-compose.yml` (xray core `v26.7.28`) and set Inbound -> Security -> Min Client Ver to `0` (see the issue above).

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

---

### 6. Enter Syncthing web-panel to setup backup folder sync to your place
All cross-machine replication links, connection pairings, and cluster synchronization settings are handled within the Syncthing Web UI. Access it at:
```text
https://${SYNC_WEB}.{DUCKDNSDOMAIN}/${SYNC_SECRET_PATH}/
```
*   **⚠️ Mandatory trailing slash:** You must append the final `/` to your secret path in the URL string, or asset paths will return a 404 block.
*   **First-Time Authentication Setup:** Syncthing will launch showing an initialization danger notification flag. Click **Actions -> Settings -> GUI** right away to enforce a strong administrative **Username** and **Password** barrier on top of your URL path block.

---

## 🐋 Practical Docker Operations Cheat Sheet

Always execute these orchestration commands directly from within your main root `docker-workspace/` directory:

*   **Fast Restart Without Rebuilding**: Safely loops the stack using the local image database without spending performance overhead running compile checkers:
    ```bash
    docker compose down && docker compose up -d
    ```
*   **Recreate the containers**: Applies new variables and configs: 
    ```bash
    docker compose down && docker compose up -d --force-recreate    
    ```
*   **Recompile and rebuild the images**: Clears old layers, completely re-compiles Caddy plugins cache, and starts all system assets:
    ```bash
    docker compose down && docker compose up -d --build
    ```
*   **Targeted Individual Service Restart**: Bypasses cycling the full workspace network chain when debugging a single node instance (e.g., `caddy`, `3x-ui`):
    ```bash
    docker compose restart [SERVICE_NAME]
    ```
*   **Real-Time Active Log Streaming**: Tracks operational system outputs and standard out error diagnostics logs interactively:
    ```bash
    docker compose logs -f [SERVICE_NAME]
    ```
*   **If your host runs critically low on storage capacity following compilation:** reclaim that wasted disk space instantly by manually dropping the compilation layer records (active containers must be spinned up to be exempted from dropping their data):
    ```bash
    docker system prune -a --volumes
    ```

---

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
The backup schedule is set in `docker-compose.yml`.

### ⚡ Recovery Restoration Workflow (pure AI-slop never tested)
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
   