# Proxmox LXC Container Deployment Scripts

This directory contains shell scripts for automating the deployment of web applications in Proxmox LXC containers. These scripts handle the complete setup process from system configuration to application deployment.

## Available Scripts

### 1. Docker Python API Deployment (v2)

**File:** [deploy_docker_python_api_v2.sh](./deploy_docker_python_api_v2.sh)

An improved version of the Docker Python API deployment script with enhanced Nginx configuration handling to prevent common errors.

**Features:**
- Automatic setup of Docker and Docker Compose
- Nginx configuration as a reverse proxy
- Let's Encrypt SSL certificate setup and auto-renewal
- GitHub repository cloning (with optional access token for private repos)
- User management with SSH key setup
- Firewall configuration with essential ports opened
- Interactive prompting for missing parameters

**Usage:**
```bash
./deploy_docker_python_api_v2.sh --repo-url [GITHUB_URL] [OPTIONS]
```

**Options:**
- `--repo-url` : GitHub repository URL to clone
- `--token` : GitHub access token for private repositories
- `--target-dir` : Directory to change into after cloning (relative to cloned repo)
- `--api-port` : Port on which the Python API will run (default: 8000)
- `--domain` : Domain name for Let's Encrypt SSL
- `--help` : Display help message

### 2. Docker Python API Deployment

**File:** [deploy_docker_python_api.sh](./deploy_docker_python_api.sh)

The original version of the Docker Python API deployment script with additional features like Cloudflare Tunnel integration.

**Features:**
- All features from v2 script
- Cloudflare Tunnel integration for secure access without exposing ports
- Support for both FastAPI and Flask frameworks
- Option for Docker deployment or direct host deployment
- Improved error handling and package management
- Repository update capability for existing deployments

**Usage:**
```bash
./deploy_docker_python_api.sh --repo-url [GITHUB_URL] [OPTIONS]
```

**Options:**
- All options from v2 script
- `--cf-tunnel` : Domain/subdomain configured in Cloudflare Tunnel

### 3. Alpine Linux Web Server Setup

**File:** [deploy_to_alpine.sh](./deploy_to_alpine.sh)

A script for setting up a complete web server environment on Alpine Linux with support for multiple application types.

**Features:**
- Support for multiple application types (Laravel, Node.js, Python, Go)
- Nginx configuration as a web server/reverse proxy
- Let's Encrypt SSL certificate setup
- User management with SSH key setup
- Firewall configuration
- Docker and Docker Compose setup (optional)
- Git repository cloning (optional)

**Usage:**
```bash
./deploy_to_alpine.sh --app-type [laravel|node|python|go]
```

**Options:**
- `--app-type` : Type of application to install (laravel, node, python, go)
- `--help` : Display help message

## Prerequisites

- A running Proxmox server with LXC container support
- Network connectivity from the container
- For Docker Python API scripts: A GitHub repository containing your Python API code
- For Alpine script: Knowledge of which application type you want to deploy

## Common Workflow

1. Create a new LXC container in Proxmox
2. Copy the appropriate script to the container
3. Make the script executable: `chmod +x script_name.sh`
4. Run the script with appropriate options or in interactive mode
5. Follow the prompts to complete the setup

## Detailed Documentation

For more detailed information about the Docker Python API deployment script, see the [README_docker_python_api.md](./README_docker_python_api.md) file.

## Troubleshooting

### Common Issues

1. **Script fails to execute**: Ensure the script has execute permissions (`chmod +x script_name.sh`)
2. **Package installation errors**: Check network connectivity and try running `apt-get update` or `apk update` manually
3. **Nginx configuration errors**: Check the Nginx error logs at `/var/log/nginx/error.log`
4. **Let's Encrypt failures**: Ensure your domain is properly pointed to the server's IP address
5. **Docker issues**: Check Docker status with `systemctl status docker` or `service docker status`

### Logs

Check these log files for troubleshooting:
- Nginx: `/var/log/nginx/error.log` and `/var/log/nginx/access.log`
- Docker: `docker logs [container_name]`
- System: `journalctl -xe` (for systemd-based distributions)

## Contributing

Contributions to improve these scripts are welcome. Please feel free to submit pull requests or open issues for bugs and feature requests.