# 🌐 Secure VPS Workspace Stack

A lightweight, portable workspace featuring reverse proxy routing via Caddy with Layer 4 support, proxy infrastructure with 3x-ui, automated workspace backup generation with real-time offsite replication via Syncthing, and active intrusion prevention powered by a containerized Fail2Ban engine tracking host SSH authentication attempts.

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
├── bscript/
│   ├── backup.sh              # Cron backup execution engine
│   └── restore.sh             # Interactive disaster recovery script
└── syncthing/                 # Syncthing database & remote cluster configuration metadata
```

---

## ⚙️ Prerequisites & Environment Setup (`.env`)

Create a `.env` file in the root workspace folder from your template example. Customize all required environment variables, making sure your system user IDs and domain routing parameters match your hosting environment before initialization.

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

## 🖥️ Web Panel Graphical User Interfaces (GUIs)

Once deployed, all administrative configurations are fully handled via web browsers using the following domain endpoints:

### 1. 3x-ui Panel Access

The proxy infrastructure console is accessible directly at your specialized subdomain URL:
```text
https://${XUI_WEB}.${DUCKDNSDOMAIN}/{XUI_SECRET_PATH}/
```
*   **Security Note:** On your very first login, secure this pane immediately by changing your admin credentials in the panel panel setting configurations.

### 2. Syncthing Dashboard Access & Pairing
All cross-machine replication links, connection pairings, and cluster synchronization settings are handled within the Syncthing Web UI. Access it at:
```text
https://\${SYNC_WEB}.DUCKDNSDOMAIN/{SYNC_SECRET_PATH}/
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
   chown -R \({USER_ID}:\){USER_ID} ./3x-ui
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

## 🛡️ Security & Intrusion Prevention

* **Non-Root Execution**: Caddy and Syncthing drop container privileges immediately upon launch via the native `user: "${USER_ID}:${USER_ID}"` directive to minimize host vulnerability vectors.
* **Network Isolation**: Syncthing port `${SYNC_PANEL_PORT}` is not exposed to the public internet interface. It can only be interfaced through Caddy's internal software bridge network (`server_network`).
* **Url Obfuscation Path Routing**: Standard scans to your root domains automatically return a dummy `404 Not Found` response. Access to the Syncthing console requires matching the hidden token variable path: `https://${SYNC_WEB}.${DUCKDNSDOMAIN}/${SYNC_SECRET_PATH}/`.
* **Active Containerized Firewall (Fail2Ban)**: Operates directly in the host network space (`network_mode: host`) with net admin capabilities. It hooks into your native system logs to intercept attacks:
  * **Host SSH protection**: Triggers a global net ban after **5** failed connection strikes.

### 📊 Fail2Ban Operations & Auditing Commands

Inspect active jail statuses and count active target blocks on your SSH interface:
```bash
docker compose exec fail2ban fail2ban-client status sshd
```

Review live container runtime filtering events:
```bash
docker compose logs fail2ban -f
```

Safely lift an accidental administrative lockout ban from your host IP address:
```bash
docker compose exec fail2ban fail2ban-client set sshd unbanip YOUR_IP_ADDRESS
```

---

## 🛠️ Backup Management & Disaster Recovery

### Run a Forced Backup Manual Execution
To capture a point-in-time checkpoint snapshot immediately before running host updates (`--force` or `-f`):
```bash
docker exec -it backup /bin/bash /workspace/bscript/backup.sh --force
```

### ⚡ Disaster Recovery Restoration Workflow (not tested)
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
