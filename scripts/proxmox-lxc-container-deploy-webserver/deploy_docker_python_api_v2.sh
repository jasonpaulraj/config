#!/bin/sh
# Docker LXC Python API Web Server Setup Script (v2)
# This script sets up a Docker container with Nginx and Let's Encrypt for Python API
# This version includes improved Nginx configuration handling to prevent common errors

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --repo-url       GitHub repository URL to clone"
    echo "  --token          GitHub access token for private repositories"
    echo "  --target-dir     Directory to change into after cloning (relative to cloned repo)"
    echo "  --api-port       Port on which the Python API will run (default: 8000)"
    echo "  --domain         Domain name for Let's Encrypt SSL"
    echo "  --help           Display this help message"
    echo ""
    echo "Note: If options are not provided as arguments, you will be prompted for input interactively."
    exit 1
}

# Function to prompt for yes/no confirmation
confirm() {
    while true; do
        printf "%s [y/n]: " "$1"
        read -r yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Parse command line arguments and/or prompt for input
REPO_URL=""
GITHUB_TOKEN=""
TARGET_DIR=""
API_PORT="8000"
DOMAIN_NAME=""

# First, check for command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --api-port)
            API_PORT="$2"
            shift 2
            ;;
        --domain)
            DOMAIN_NAME="$2"
            shift 2
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown parameter: $1"
            show_usage
            ;;
    esac
done

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$DISTRIB_ID
    DISTRO_VERSION=$DISTRIB_VERSION
else
    DISTRO=$(uname -s)
    DISTRO_VERSION=$(uname -r)
fi
echo "Detected distribution: $DISTRO $DISTRO_VERSION"

# Then, prompt for any missing parameters
# Prompt for GitHub repository URL if not provided
if [ -z "$REPO_URL" ]; then
    echo "Enter GitHub repository URL to clone:"
    read -r REPO_URL
    
    # Validate input
    if [ -z "$REPO_URL" ]; then
        echo "Error: GitHub repository URL is required"
        exit 1
    fi
fi

# Prompt for GitHub token if not provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Do you want to provide a GitHub access token for private repositories?"
    if confirm "Provide GitHub token"; then
        echo "Enter GitHub access token:"
        read -r GITHUB_TOKEN
    fi
fi

# Prompt for target directory if not provided
if [ -z "$TARGET_DIR" ]; then
    echo "Do you want to specify a target directory within the repository?"
    if confirm "Specify target directory"; then
        echo "Enter target directory (relative to cloned repo):"
        read -r TARGET_DIR
    fi
fi

# Prompt for API port if still at default
if [ "$API_PORT" = "8000" ]; then
    echo "Do you want to change the default API port (8000)?"
    if confirm "Change API port"; then
        echo "Enter API port:"
        read -r API_PORT
    fi
fi

# Inform user about port 80 configuration
echo "Note: The application will be accessible on port 80 via Nginx, regardless of the API port setting."

# Prompt for domain name if not provided
if [ -z "$DOMAIN_NAME" ]; then
    echo "Do you want to set up SSL with Let's Encrypt now?"
    if confirm "Set up Let's Encrypt"; then
        echo "Enter your domain name (e.g., example.com):"
        read -r DOMAIN_NAME
    fi
fi

echo "===== Starting Docker Python API Web Server Setup ====="

# Step 1: Set up basic system components
echo "===== Step 1: Setting up basic system components ====="
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

echo "Installing essential packages..."
apt-get install -y curl wget git vim sudo bash openssh-server

# SSH server setup
systemctl enable ssh
systemctl start ssh

# User management
echo "Do you want to create a new user?"
if confirm "Create new user"; then
    echo "Enter username for the new user:"
    read -r NEW_USER
    
    # Check if user already exists
    if id "$NEW_USER" >/dev/null 2>&1; then
        echo "User $NEW_USER already exists."
        echo "Do you want to reconfigure this user?"
        if confirm "Reconfigure user"; then
            # Reconfiguration options
            echo "Do you want to reset the password for $NEW_USER?"
            if confirm "Reset password"; then
                passwd "$NEW_USER"
            fi
        else
            echo "Skipping user configuration for $NEW_USER"
        fi
    else
        # Create the user
        echo "Creating new user $NEW_USER..."
        adduser "$NEW_USER"
    fi
    
    # Add user to sudo group for sudo access if not already a member
    if ! groups "$NEW_USER" | grep -q sudo; then
        echo "%sudo ALL=(ALL) ALL" > /etc/sudoers.d/sudo
        usermod -aG sudo "$NEW_USER"
        echo "Added $NEW_USER to sudo group"
    else
        echo "User $NEW_USER is already in the sudo group"
    fi
    
    # Set up SSH key for the user (works for both new and existing users)
    echo "Do you want to add or update an SSH public key for $NEW_USER?"
    if confirm "Add/update SSH key"; then
        mkdir -p /home/"$NEW_USER"/.ssh
        chmod 700 /home/"$NEW_USER"/.ssh
        echo "Paste the SSH public key for $NEW_USER (then press Ctrl+D):"
        cat > /home/"$NEW_USER"/.ssh/authorized_keys
        chmod 600 /home/"$NEW_USER"/.ssh/authorized_keys
        chown -R "$NEW_USER":"$NEW_USER" /home/"$NEW_USER"/.ssh
        echo "SSH key added/updated for $NEW_USER"
    fi
    
    # Ask about disabling root SSH access
    echo "Do you want to disable root SSH login?"
    if confirm "Disable root SSH"; then
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        service sshd restart
        echo "Root SSH login has been disabled"
    fi
else
    # If no new user, ask about SSH key for root
    echo "Do you want to add an SSH public key for root?"
    if confirm "Add SSH key"; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        echo "Paste your SSH public key (then press Ctrl+D):"
        cat > /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        echo "SSH key added successfully"
    fi
fi

# Step 2: Install Docker and Docker Compose
echo "===== Step 2: Installing Docker and Docker Compose ====="
echo "Installing Docker..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

echo "Installing Docker Compose dependencies..."
apt-get install -y python3-pip gcc python3-dev libffi-dev libssl-dev

echo "Installing Docker Compose..."
pip3 install docker-compose

# Step 3: Set up Nginx
echo "===== Step 3: Setting up Nginx web server ====="
apt-get install -y nginx

# Backup original Nginx configuration
if [ -f /etc/nginx/nginx.conf ]; then
    echo "Backing up original Nginx configuration..."
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
fi

# Determine Nginx user
NGINX_USER="www-data"  # Default for Debian/Ubuntu
echo "Using Nginx user: $NGINX_USER"

# Determine Nginx configuration structure
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"

# Check if the distribution uses a different structure
if [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
    SITES_AVAILABLE="/etc/nginx/conf.d"
    SITES_ENABLED="/etc/nginx/conf.d"
    # Create directory if it doesn't exist
    mkdir -p $SITES_AVAILABLE
elif [ "$DISTRO" = "alpine" ]; then
    SITES_AVAILABLE="/etc/nginx/conf.d"
    SITES_ENABLED="/etc/nginx/conf.d"
    mkdir -p $SITES_AVAILABLE
else
    # For Debian/Ubuntu and others, create the directories if they don't exist
    mkdir -p $SITES_AVAILABLE $SITES_ENABLED
fi

echo "Using Nginx configuration directories:"
echo "  Sites available: $SITES_AVAILABLE"
echo "  Sites enabled: $SITES_ENABLED"

# Create a basic Nginx configuration
cat > /etc/nginx/nginx.conf << EOF
user $NGINX_USER;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Include site configurations
EOF

# Add the appropriate include directive based on the distribution
if [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "alpine" ]; then
    echo "    include $SITES_AVAILABLE/*.conf;" >> /etc/nginx/nginx.conf
else
    echo "    include $SITES_ENABLED/*.conf;" >> /etc/nginx/nginx.conf
fi

# Close the http block
echo "}" >> /etc/nginx/nginx.conf

# Ensure mime.types exists
if [ ! -f /etc/nginx/mime.types ]; then
    echo "Creating mime.types file..."
    cat > /etc/nginx/mime.types << 'EOF'
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;

    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/x-component                      htc;

    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/x-icon                          ico;
    image/x-jng                           jng;
    image/x-ms-bmp                        bmp;
    image/svg+xml                         svg svgz;
    image/webp                            webp;

    application/font-woff                 woff;
    application/java-archive              jar war ear;
    application/json                      json;
    application/mac-binhex40              hqx;
    application/msword                    doc;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.apple.mpegurl         m3u8;
    application/vnd.ms-excel              xls;
    application/vnd.ms-fontobject         eot;
    application/vnd.ms-powerpoint         ppt;
    application/vnd.wap.wmlc              wmlc;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/x-7z-compressed           7z;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xspf+xml                  xspf;
    application/zip                       zip;

    application/octet-stream              bin exe dll;
    application/octet-stream              deb;
    application/octet-stream              dmg;
    application/octet-stream              iso img;
    application/octet-stream              msi msp msm;

    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

    audio/midi                            mid midi kar;
    audio/mpeg                            mp3;
    audio/ogg                             ogg;
    audio/x-m4a                           m4a;
    audio/x-realaudio                     ra;

    video/3gpp                            3gpp 3gp;
    video/mp2t                            ts;
    video/mp4                             mp4;
    video/mpeg                            mpeg mpg;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-m4v                           m4v;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;
}
EOF
fi

# Step 4: Clone repository
echo "===== Step 4: Setting up application code ====="
mkdir -p /var/www

# Extract repository name from URL
REPO_NAME=$(basename "$REPO_URL" .git)

# Clone the repository
echo "Cloning repository from $REPO_URL..."
if [ -n "$GITHUB_TOKEN" ]; then
    # Extract username and repo from URL
    REPO_PATH=$(echo "$REPO_URL" | sed -E 's|https://github.com/||' | sed -E 's|.git$||')
    
    # Clone with token
    git clone "https://$GITHUB_TOKEN@github.com/$REPO_PATH.git" "/var/www/$REPO_NAME"
else
    # Clone without token
    git clone "$REPO_URL" "/var/www/$REPO_NAME"
fi

# Set base directory
BASE_DIR="/var/www/$REPO_NAME"

# Change to target directory if specified
APP_DIR="$BASE_DIR"
if [ -n "$TARGET_DIR" ]; then
    if [ -d "$BASE_DIR/$TARGET_DIR" ]; then
        APP_DIR="$BASE_DIR/$TARGET_DIR"
        echo "Changed to target directory: $APP_DIR"
    else
        echo "Warning: Target directory '$TARGET_DIR' not found in the repository"
    fi
fi

# Create Nginx site configuration for Python API
echo "Creating Nginx site configuration..."
SITE_CONFIG_FILE="$SITES_AVAILABLE/default.conf"
cat > "$SITE_CONFIG_FILE" << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root $APP_DIR;
    index index.html index.htm;
    
    server_name _;
    
    # Main location block to proxy all requests to the Python API
    location / {
        proxy_pass http://localhost:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    # Additional security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

# Enable the site (create symlink if using sites-enabled)
if [ "$SITES_AVAILABLE" != "$SITES_ENABLED" ]; then
    ln -sf "$SITE_CONFIG_FILE" "$SITES_ENABLED/"
fi

# Test Nginx configuration before enabling
echo "Testing Nginx configuration..."
nginx -t

# Only proceed if the test is successful
if [ $? -eq 0 ]; then
    echo "Nginx configuration test successful."
    systemctl enable nginx
else
    echo "Nginx configuration test failed. Please check the configuration."
    echo "You may need to manually fix the configuration before continuing."
    # Don't exit the script, but warn the user
    echo "WARNING: Continuing with the script, but Nginx may not start properly."
fi

# Step 5: Create Docker Compose file if it doesn't exist
if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
    echo "No docker-compose.yml found. Creating a basic one for Python API..."
    cat > "$APP_DIR/docker-compose.yml" << EOF
version: '3'

services:
  api:
    build:
      context: .
    # Only expose port internally, not to the host directly
    # This ensures all traffic goes through Nginx
    expose:
      - "$API_PORT"
    volumes:
      - .:/app
    restart: unless-stopped
    environment:
      - PORT=$API_PORT
    networks:
      - web_network

networks:
  web_network:
    driver: bridge
EOF

    # Create a basic Dockerfile if it doesn't exist
    if [ ! -f "$APP_DIR/Dockerfile" ]; then
        echo "Creating a basic Dockerfile..."
        cat > "$APP_DIR/Dockerfile" << EOF
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE $API_PORT

CMD ["python", "app.py"]
EOF
    fi

    # Create a basic requirements.txt if it doesn't exist
    if [ ! -f "$APP_DIR/requirements.txt" ]; then
        echo "Creating a basic requirements.txt..."
        cat > "$APP_DIR/requirements.txt" << EOF
flask==2.0.1
gunicorn==20.1.0
EOF
    fi
fi

# Step 6: Firewall setup
echo "===== Step 6: Setting up firewall ====="
echo "Installing and configuring firewall..."
apt-get install -y ufw

# Configure basic firewall rules
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow ssh

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow the API port if different from 80
if [ "$API_PORT" != "80" ]; then
    ufw allow "$API_PORT"/tcp
fi

# Enable firewall (non-interactive)
echo "y" | ufw enable
echo "Firewall configured and enabled"

# Step 7: Let's Encrypt setup
echo "===== Step 7: Setting up Let's Encrypt ====="
if [ -n "$DOMAIN_NAME" ]; then
    echo "Setting up Let's Encrypt for $DOMAIN_NAME..."
    
    # Install certbot and the appropriate plugin based on distribution
    if [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
        # For CentOS/RHEL/Fedora
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y certbot python3-certbot-nginx
        else
            yum install -y certbot python3-certbot-nginx
        fi
    elif [ "$DISTRO" = "alpine" ]; then
        # For Alpine
        apk add --no-cache certbot certbot-nginx
    else
        # For Debian/Ubuntu and others
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Update Nginx configuration with domain name
    sed -i "s/server_name _;/server_name $DOMAIN_NAME;/" "$SITE_CONFIG_FILE"
    
    # Test Nginx configuration again after the change
    echo "Testing Nginx configuration after domain update..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        echo "Nginx configuration test successful."
        systemctl reload nginx
        
        # Run certbot to obtain SSL certificate
        echo "Obtaining SSL certificate..."
        certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email webmaster@"$DOMAIN_NAME" --redirect
        
        if [ $? -eq 0 ]; then
            echo "SSL certificate obtained successfully."
            
            # Set up auto-renewal
            echo "Setting up automatic certificate renewal..."
            echo "0 3 * * * certbot renew --quiet" | crontab -
            
            echo "Let's Encrypt SSL certificate installed and auto-renewal configured"
        else
            echo "Failed to obtain SSL certificate. You can try manually later with:"
            echo "certbot --nginx -d $DOMAIN_NAME"
        fi
    else
        echo "Nginx configuration test failed after domain update."
        echo "Skipping Let's Encrypt setup. You can manually set up SSL later."
    fi
else
    echo "No domain name provided. Skipping Let's Encrypt setup."
    echo "You can manually set up SSL later by running certbot."
fi

# Step 8: Start Docker Compose
echo "===== Step 8: Starting Docker Compose ====="
cd "$APP_DIR"

if [ -f "docker-compose.yml" ]; then
    echo "Starting Docker Compose..."
    docker-compose up -d
    echo "Docker Compose started successfully"
else
    echo "No docker-compose.yml file found in $APP_DIR"
fi

# Restart Nginx to apply changes
echo "Restarting Nginx to apply changes..."
systemctl restart nginx

# Check if Nginx started successfully
if systemctl is-active --quiet nginx; then
    echo "Nginx started successfully."
else
    echo "WARNING: Nginx failed to start. You may need to fix the configuration manually."
    echo "Check the logs with: journalctl -u nginx.service"
fi

echo "===== Setup Complete ====="
echo "Your Python API with Docker has been set up successfully!"
echo "Web server is running at http://$(hostname -I | awk '{print $1}')"
if [ -n "$DOMAIN_NAME" ]; then
    echo "Your application is also available at https://$DOMAIN_NAME"
fi
