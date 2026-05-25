# Anti-Spam SMTP Proxy (ASSP) Docker Container

This repository contains a Docker configuration to build a lightweight, containerized instance of the **ASSP (Anti-Spam SMTP Proxy)** mail filter server, based on Alpine Linux.

ASSP is an open-source, platform-independent SMTP proxy server that sits in front of your primary mail server (e.g. Postfix, Exim, Exchange) and uses a variety of advanced spam-filtering techniques to intercept and block spam before it reaches the mail server.

---

## Features

- **Alpine Base:** Extremely lightweight and secure container footprint.
- **ASSP V2 Multithreading:** Configured to run the latest multithreaded release of ASSP.
- **Web File Commander:** Pre-integrated with Web File Commander (version 1.05) and auxiliary libraries (`lib.zip`) for easy admin file access via the web UI.
- **ClamAV Integration:** Pre-installed ClamAV client (`clamav` package) and corresponding Perl scanning modules (`File::Scan::ClamAV`) for antivirus email scanning.
- **Supervisor Daemon:** Monitored and managed automatically via Supervisor for automatic restarts.
- **Comprehensive Perl Stack:** Preloaded with all required CPAN/native Perl dependencies including BerkeleyDB, CryptX, SSL/TLS components, and database drivers (MariaDB, PostgreSQL, SQLite).

---

## Exposed Ports

The container exposes the standard ASSP networking ports:

| Port | Description |
|---|---|
| **`55555`** | ASSP Web Administration Interface (HTTP/HTTPS) |
| **`25`** | Incoming SMTP Proxy Port |
| **`225`** | Alternate SMTP Port |
| **`465`** | Secure SMTPS Proxy Port |

---

## Volumes & Persistence

To ensure configurations, learning corpora, and SSL certificates persist across container updates, map the following volumes:

- `/etc/assp` – Configuration folder containing `assp.cfg`.
- `/usr/share/assp/certs` – SSL certificates for SMTP and HTTPS administrations.
- `/usr/share/assp/files` – General files database and internal settings.
- `/usr/share/assp/spam` – Spam corpus for Bayesian learning.
- `/usr/share/assp/notspam` – Ham corpus for Bayesian learning.
- `/usr/share/assp/errors` – Spam quarantine and processing error directory.

---

## Usage

### 1. Build the Image

Build the container image locally:

```bash
docker build -t assp-docker .
```

### 2. Run the Container

Start the proxy server container mapping the necessary administration and mail filtering ports, along with persistent volumes:

```bash
docker run -d \
  --name assp-service \
  -p 25:25 \
  -p 225:225 \
  -p 465:465 \
  -p 55555:55555 \
  -v /opt/assp/config:/etc/assp \
  -v /opt/assp/certs:/usr/share/assp/certs \
  -v /opt/assp/files:/usr/share/assp/files \
  -v /opt/assp/spam:/usr/share/assp/spam \
  -v /opt/assp/notspam:/usr/share/assp/notspam \
  -v /opt/assp/errors:/usr/share/assp/errors \
  --restart unless-stopped \
  assp-docker
```
