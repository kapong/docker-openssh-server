# OpenSSH Server Docker Container

[![GitHub](https://img.shields.io/badge/GitHub-kapong%2Fdocker--openssh--server-blue?logo=github)](https://github.com/kapong/docker-openssh-server)
[![Docker](https://img.shields.io/badge/Docker-ghcr.io%2Fkapong%2Fopenssh--server-2496ED?logo=docker&logoColor=white)](https://ghcr.io/kapong/openssh-server)

A lightweight, secure OpenSSH server container based on [LinuxServer.io's openssh-server](https://github.com/linuxserver/docker-openssh-server). This fork includes substantial modifications and enhancements, including Python environment options and optimizations for remote development workflows.

## Features

- 🔐 Multiple authentication methods (SSH keys, passwords, GitHub keys)
- 🐍 Pre-configured Python environments (3.11 - 3.14) or base image without Python
- 💻 Full compatibility with VS Code Remote - SSH extension
- 🎯 User/group ID mapping for seamless file permissions
- 🔒 Docker secrets support for sensitive credentials
- 🚀 GPU passthrough support (NVIDIA Container Toolkit)
- 📦 Shared package cache support (UV cache example included)

## Available Tags

| Tag | Description | Use Case |
|-----|-------------|----------|
| `base` | Base image without Python | Minimal footprint, custom environments |
| `py311` | Python 3.11 | Legacy projects |
| `py312` | Python 3.12 | Stable Python version |
| `py313` | Python 3.13 (default) | Latest stable release |
| `py314` | Python 3.14 | Bleeding edge features |

## Quick Start

```bash
docker run -d \
  --name openssh-server \
  -e PUBLIC_KEY_URL=https://github.com/yourusername.keys \
  -e USER_NAME=yourname \
  -p 2222:2222 \
  -v ./config:/config \
  -v ./workspace:/workspace \
  ghcr.io/kapong/openssh-server:latest
```

Connect via SSH:
```bash
ssh -p 2222 yourname@localhost
```

## Configuration

### Authentication Methods

**SSH Key Authentication (Recommended):**

### Permissions & Access

- Set `SUDO_ACCESS=true` for sudo privileges (passwordless by default)
- Add `USER_PASSWORD` for password-protected sudo
- Users are restricted to mapped volumes and container processes
- Use `PUID`/`PGID` to match host user permissions

### Customization

- **Custom MOTD**: Mount your text file to `/etc/motd`
- **Hostname**: Set via Docker `--hostname` argument
- **Multiple Instances**: Run separate containers with different ports and keys for isolated access


## SSH Key Generation

Generate a new SSH key pair using the included helper:

```bash
docker run --rm -it --entrypoint /keygen.sh ghcr.io/kapong/openssh-server
```

**⚠️ Important**: Keys are displayed only once. Save them immediately to a secure location.

## VS Code Remote Development

This container is optimized for use with [VS Code Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh).

### Setup Instructions

1. **Configure SSH Connection** - Add to `~/.ssh/config`:

```ssh-config
Host my-dev-container
    HostName localhost  # or your server IP/domain
    Port 2222
    User linuxserver.io
    IdentityFile ~/.ssh/your_private_key
```

2. **Connect from VS Code**:
   - Press `F1` or `Ctrl+Shift+P`
   - Select `Remote-SSH: Connect to Host...`
   - Choose `my-dev-container`

3. **Access Workspace**: Your mounted volumes are accessible at their container paths (e.g., `/workspace`)

### Benefits

- Full VS Code experience in containerized environment
- Install extensions directly in the remote environment
- Use container's Python interpreter and tools
- Seamless file editing with proper permissions

## Usage Examples

### Basic Docker Compose

```yaml
---
services:
  openssh-server:
    image: ghcr.io/kapong/openssh-server:latest
    container_name: openssh-server
    hostname: openssh-server #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - PUBLIC_KEY=yourpublickey #optional
      - PUBLIC_KEY_FILE=/path/to/file #optional
      - PUBLIC_KEY_DIR=/path/to/directory/containing/_only_/pubkeys #optional
      - PUBLIC_KEY_URL=https://github.com/username.keys #optional
      - SUDO_ACCESS=false #optional
      - PASSWORD_ACCESS=false #optional
      - USER_PASSWORD=password #optional
      - USER_PASSWORD_FILE=/path/to/file #optional
      - USER_NAME=linuxserver.io #optional
      - LOG_STDOUT= #optional
    volumes:
      - /path/to/openssh-server/config:/config
    ports:
      - 2222:2222
    restart: unless-stopped
```

### Docker CLI

```bash
docker run -d \
  --name=openssh-server \
  --hostname=openssh-server `#optional` \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e PUBLIC_KEY=yourpublickey `#optional` \
  -e PUBLIC_KEY_FILE=/path/to/file `#optional` \
  -e PUBLIC_KEY_DIR=/path/to/directory/containing/_only_/pubkeys `#optional` \
  -e PUBLIC_KEY_URL=https://github.com/username.keys `#optional` \
  -e SUDO_ACCESS=false `#optional` \
  -e PASSWORD_ACCESS=false `#optional` \
  -e USER_PASSWORD=password `#optional` \
  -e USER_PASSWORD_FILE=/path/to/file `#optional` \
  -e USER_NAME=linuxserver.io `#optional` \
  -e LOG_STDOUT= `#optional` \
  -p 2222:2222 \
  -v /path/to/openssh-server/config:/config \
  --restart unless-stopped \
  ghcr.io/kapong/openssh-server:latest
```

### Multi-User Setup with GPU Support

Perfect for team environments with shared resources:

```yaml
name: kapong-test

x-base-env: &base-env
  PUID: 1000
  PGID: 1000
  TZ: Asia/Bangkok
  SUDO_ACCESS: true
  PASSWORD_ACCESS: false
  LOG_STDOUT: ""

x-openssh-base: &openssh-base
  image: ghcr.io/kapong/openssh-server:py313
  working_dir: /workspace
  shm_size: 4gb
  restart: unless-stopped
  deploy:
    replicas: 1
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]

x-uv-cache-vol: &uv-cache-vol uv-cache:/config/.cache/uv

services:
  kapong:
    <<: *openssh-base
#    image: ghcr.io/kapong/openssh-server:py314
    environment:
      <<: *base-env
      PUBLIC_KEY_URL: https://github.com/kapong.keys
      USER_NAME: kapong
    volumes:
      - *uv-cache-vol
      - ./kapong-home:/config
      - ./kapong-workspace:/workspace
    ports:
      - 2222:2222
  johndoe:
    <<: *openssh-base
#    image: ghcr.io/kapong/openssh-server:py314
    environment:
      <<: *base-env
      PUBLIC_KEY: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy..."  # replace with actual key
      USER_NAME: johndoe
    volumes:
      - *uv-cache-vol
      - ./johndoe-home:/config
      - ./johndoe-workspace:/workspace
    ports:
      - 2223:2222

volumes:
  uv-cache:
```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TZ` | `Etc/UTC` | Timezone ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)) |
| `USER_NAME` | `linuxserver.io` | SSH username |
| `PUBLIC_KEY` | - | SSH public key string |
| `PUBLIC_KEY_FILE` | - | Path to public key file |
| `PUBLIC_KEY_DIR` | - | Directory with public keys |
| `PUBLIC_KEY_URL` | - | URL to fetch public keys (e.g., GitHub) |
| `PASSWORD_ACCESS` | `false` | Enable password authentication |
| `USER_PASSWORD` | - | User/sudo password |
| `USER_PASSWORD_FILE` | - | Path to password file (overrides `USER_PASSWORD`) |
| `SUDO_ACCESS` | `false` | Grant sudo privileges |
| `LOG_STDOUT` | `false` | Log to stdout instead of file |

## Volumes

| Container Path | Description |
|----------------|-------------|
| `/config` | User home directory, SSH config, authorized_keys |
| `/workspace` | Recommended mount point for project files |

## Ports

| Port | Description |
|------|-------------|
| `2222` | SSH server (default) |

## Advanced Configuration

### Docker Secrets

For sensitive data in production environments:

```yaml
secrets:
  ssh_password:
    file: ./secrets/password.txt

services:
  openssh-server:
    image: ghcr.io/kapong/openssh-server:latest
    environment:
      - USER_PASSWORD_FILE=/run/secrets/ssh_password
    secrets:
      - ssh_password
```

### Using `FILE__` Prefix

Set any environment variable from a file:
```bash
-e FILE__USER_PASSWORD=/run/secrets/password
```

### User/Group ID Mapping

Match container user to host user to prevent permission issues:

```bash
# Find your user/group IDs
id yourusername
# Output: uid=1000(yourusername) gid=1000(yourusername) ...

# Use in container
docker run -e PUID=1000 -e PGID=1000 ...
```

## Use Cases

- **Remote Development**: Connect via VS Code Remote SSH for full IDE experience
- **Secure File Access**: Grant limited SSH access to specific directories
- **Automated Backups**: Restrict remote backup tools to designated folders
- **Multi-User Environments**: Isolate user workspaces with separate containers
- **CI/CD Integration**: Provide secure SSH access for deployment pipelines
- **GPU Workloads**: Run ML/AI development environments with GPU passthrough

## Support & Contributing

- **Issues**: [GitHub Issues](https://github.com/kapong/docker-openssh-server/issues)
- **Source**: [GitHub Repository](https://github.com/kapong/docker-openssh-server)

## License

See [LICENSE](LICENSE) file for details.

---

**Acknowledgments**: Based on [LinuxServer.io's openssh-server](https://github.com/linuxserver/docker-openssh-server) with significant modifications.

