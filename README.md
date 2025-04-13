# Cloud & DevOps Configuration Repository

## File Legend

- [Docker Services Reference](DOCKER_SERVICES.MD)
- [Programming Daily Backup Task](programming_daily_backup_task.bat)
- [Home Assistant Config](homeassistant/configuration.yaml)
- [WezTerm Config](wezterm/)
- [Proxmox Deployment Docs](scripts/proxmox-lxc-container-deploy-webserver/README.md)

A comprehensive collection of configuration files, deployment scripts, and infrastructure templates for various cloud services, containers, and development tools. This repository serves as a reference for DevOps engineers, cloud architects, and developers looking to implement best practices for deployment and configuration management.

## Table of Contents

- [Docker Configurations](#docker-configurations)
  - [Docker Compose Templates](#docker-compose-templates)
  - [Dockerfile Templates](#dockerfile-templates)
- [Cloud Deployment Templates](#cloud-deployment-templates)
- [Scripts](#scripts)
  - [Proxmox LXC Container Deployment](#proxmox-lxc-container-deployment)
  - [GitHub Utilities](#github-utilities)
  - [cURL Testing](#curl-testing)
  - [Windows Scripts](#windows-scripts)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Documentation](#documentation)
- [Home Assistant Configurations](#home-assistant-configurations)
- [Terminal Configurations](#terminal-configurations)

## Docker Configurations

### Docker Compose Templates

- [**Laravel Apache**](docker-compose/laravel-apache/) - Docker Compose setup for Laravel applications with Apache web server.
- [**Laravel FPM**](docker-compose/laravel-fpm/) - Docker Compose setup for Laravel applications with PHP-FPM and Nginx.
- [**Portainer**](docker-compose/portainer/) - Collection of Docker Compose files for Portainer and related services:
  - [Grafana](docker-compose/portainer/grafana.yml) - Metrics visualization platform
  - [Homepage Dashboard](docker-compose/portainer/homepage-dashboard.yml) - Web dashboard for services
  - [MySQL](docker-compose/portainer/mysql.yml) - MySQL database server
  - [Uptime Kuma](docker-compose/portainer/uptime-kuma.yml) - Uptime monitoring tool
- [**Prometheus + Grafana**](docker-compose/prometheus+grafana/) - Monitoring stack with Prometheus and Grafana.
- [**Prometheus**](docker-compose/prometheus/) - Prometheus monitoring system standalone setup.

### Dockerfile Templates

- [**Nginx**](docker_file/nginx/Dockerfile) - Custom Nginx web server configuration.
- [**PHP Apache**](docker_file/php-apache/Dockerfile) - PHP with Apache web server setup.
- [**PHP FPM**](docker_file/php-fpm/Dockerfile) - PHP-FPM configuration for high-performance PHP applications.

### Docker Services

- [**Docker Services Reference**](DOCKER_SERVICES.MD) - Quick reference for common Docker service commands including Pi-hole, AdGuard Home, and MySQL.

## Cloud Deployment Templates

- [**React Web Applications**](cloud-deployments/react-web/)
  - [Basic SCP Deployment](cloud-deployments/react-web/basic-scp/) - Guide for deploying React applications to Linux servers using SCP and Nginx.
- [**Terraform Templates**](cloud-deployments/terraform/)
  - [Laravel AWS](cloud-deployments/terraform/laravel-aws/) - Terraform configuration for deploying Laravel applications on AWS.
  - [React Web](cloud-deployments/terraform/react-web/) - Terraform configuration for deploying React applications.

## Scripts

### Proxmox LXC Container Deployment

- [**Proxmox LXC Container Deployment Scripts**](scripts/proxmox-lxc-container-deploy-webserver/) - Collection of scripts for automating web application deployment in Proxmox LXC containers:
  - [Documentation](scripts/proxmox-lxc-container-deploy-webserver/README.md) - Comprehensive guide for all deployment scripts
  - [Docker Python API Deployment](scripts/proxmox-lxc-container-deploy-webserver/deploy_docker_python_api.sh) - Script for deploying Python API applications in Docker containers on Proxmox LXC
  - [Docker Python API Deployment v2](scripts/proxmox-lxc-container-deploy-webserver/deploy_docker_python_api_v2.sh) - Improved version with enhanced Nginx configuration handling
  - [Alpine Deployment](scripts/proxmox-lxc-container-deploy-webserver/deploy_to_alpine.sh) - Script for deploying various application types to Alpine Linux containers

### GitHub Utilities

- [**GitHub Repository Downloader**](scripts/github/) - Script to download all repositories from a GitHub account with filtering options.

### cURL Testing

- [**cURL Test Scripts**](scripts/curl/)
  - [Test cURL](scripts/curl/test_curl.sh) - Basic script for testing cURL requests with fixed parameters.
  - [Dynamic cURL](scripts/curl/dynamic_curl.sh) - Flexible script for testing cURL requests with dynamic parameters.

### Windows Scripts

- [**Windows Firewall Configuration**](scripts/windows/Firewall_Inbound_Outbound_Connection/) - Scripts for configuring Windows Firewall rules.
- [**Windows 10 Debloater**](scripts/windows/Windows_10_Debloater/) - Scripts to remove bloatware from Windows 10.
- [**Windows 11 Debloater**](scripts/windows/Windows_11_Debloater/) - Scripts to remove bloatware from Windows 11.
- [**Daily Disk Backup**](scripts/windows/daily_disk_backup_task_scheduler/) - Task scheduler scripts for automated disk backups.
- [**Programming Daily Backup Task**](programming_daily_backup_task.bat) - Batch script for daily backup of programming projects.

## GitHub Actions Workflows

- [**Laravel CI/CD**](github-actions/laravel/) - GitHub Actions workflows for Laravel applications.
- [**React Web CI/CD**](github-actions/react-web/) - GitHub Actions workflows for React web applications.

## Documentation

- [**Deploy React Web on Oracle/Fedora**](documentation/Deploy-React-Web-Nginx-Linux-Oracle-Fedora-Server.md) - Guide for deploying React applications on Oracle Linux or Fedora Server with Nginx.
- [**Oracle Linux/Fedora YUM RPMDB Error**](documentation/oracle-linux-fedora-yum-rpmdb-open-failed-error.md) - Troubleshooting guide for YUM RPMDB errors on Oracle Linux or Fedora.
- [**Windows Command Line with Whitespace**](documentation/windows-folder-with-whitespace-on-commandline.md) - Guide for handling Windows paths with whitespace in command line operations.

## Home Assistant Configurations

- [**Home Assistant Configuration Files**](homeassistant/)
  - [Automations](homeassistant/automations.yaml) - Home Assistant automation configurations.
  - [Configuration](homeassistant/configuration.yaml) - Main Home Assistant configuration.
  - [Scenes](homeassistant/scenes.yaml) - Home Assistant scene configurations.
  - [Scripts](homeassistant/scripts.yaml) - Home Assistant script configurations.
  - [Sensors](homeassistant/sensors.yaml) - Home Assistant sensor configurations.

## Terminal Configurations

- [**WezTerm Configuration**](wezterm/) - Configuration files for the WezTerm terminal emulator.
