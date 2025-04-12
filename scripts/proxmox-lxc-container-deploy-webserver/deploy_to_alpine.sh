#!/bin/sh
# Alpine Linux Web Server Setup Script
# This script sets up a complete web server environment on Alpine Linux

# Function to display usage information
show_usage() {
    echo "Usage: $0 --app-type [laravel|node|python|go]"
    echo "Options:"
    echo "  --app-type    Type of application to install (laravel, node, python, go)"
    echo "  --help        Display this help message"
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

# Parse command line arguments
APP_TYPE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app-type)
            APP_TYPE="$2"
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

# Validate app type
if [ -z "$APP_TYPE" ]; then
    echo "Error: Application type is required"
    show_usage
fi

case "$APP_TYPE" in
    laravel|node|python|go)
        echo "Setting up environment for $APP_TYPE application"
        ;;
    *)
        echo "Error: Invalid application type. Choose from: laravel, node, python, go"
        show_usage
        ;;
esac

echo "===== Starting Web Server Setup ====="

# Step 1: Set up Linux related stuff
echo "===== Step 1: Setting up basic system components ====="
echo "Updating Alpine packages..."
apk update && apk upgrade

echo "Installing SSH server..."
apk add openssh
rc-update add sshd default
service sshd start

# User management
echo "Do you want to create a new user?"
if confirm "Create new user"; then
    echo "Enter username for the new user:"
    read -r NEW_USER
    
    # Create the user
    adduser -D "$NEW_USER"
    echo "Enter password for $NEW_USER:"
    passwd "$NEW_USER"
    
    # Add user to wheel group for sudo access
    apk add sudo
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
    adduser "$NEW_USER" wheel
    
    # Set up SSH key for the new user
    echo "Do you want to add an SSH public key for $NEW_USER?"
    if confirm "Add SSH key"; then
        mkdir -p /home/"$NEW_USER"/.ssh
        chmod 700 /home/"$NEW_USER"/.ssh
        echo "Paste the SSH public key for $NEW_USER (then press Ctrl+D):"
        cat > /home/"$NEW_USER"/.ssh/authorized_keys
        chmod 600 /home/"$NEW_USER"/.ssh/authorized_keys
        chown -R "$NEW_USER":"$NEW_USER" /home/"$NEW_USER"/.ssh
        echo "SSH key added for $NEW_USER"
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

echo "Installing common dependencies..."
apk add curl wget git vi sudo bash

# Step 2 & 3: Install application-specific dependencies
echo "===== Step 2 & 3: Installing $APP_TYPE dependencies ====="

case "$APP_TYPE" in
    laravel)
        echo "Installing PHP and related packages..."
        apk add php8 php8-fpm php8-opcache php8-gd php8-mysqli php8-zlib php8-curl \
            php8-phar php8-json php8-mbstring php8-dom php8-tokenizer php8-xml \
            php8-pdo php8-pdo_mysql php8-fileinfo php8-openssl php8-zip php8-session \
            php8-ctype php8-simplexml
        
        rc-update add php-fpm8 default
        service php-fpm8 start
        
        echo "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        ;;
        
    node)
        echo "Installing Node.js and npm..."
        apk add nodejs npm
        
        echo "Installing PM2 for process management..."
        npm install -g pm2
        ;;
        
    python)
        echo "Installing Python and related packages..."
        apk add python3 py3-pip python3-dev
        
        echo "Installing virtual environment tools..."
        pip3 install virtualenv
        ;;
        
    go)
        echo "Installing Go..."
        apk add go
        ;;
esac

# Step 4: Set up Nginx
echo "===== Step 4: Setting up Nginx web server ====="
apk add nginx
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
rc-update add nginx default

# Create a basic Nginx configuration
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Include site configurations
    include /etc/nginx/sites-enabled/*.conf;
}
EOF

# Step 5: Clone repository
echo "===== Step 5: Setting up application code ====="
mkdir -p /var/www
echo "Do you want to clone a Git repository?"
if confirm "Clone repository"; then
    echo "Enter GitHub repository URL (e.g., https://github.com/username/repo.git):"
    read -r REPO_URL
    
    echo "Do you need to use a GitHub access token?"
    if confirm "Use GitHub token"; then
        echo "Enter your GitHub access token:"
        read -r GITHUB_TOKEN
        
        # Extract username and repo from URL
        REPO_PATH=$(echo "$REPO_URL" | sed -E 's|https://github.com/||' | sed -E 's|.git$||')
        
        # Clone with token
        git clone "https://$GITHUB_TOKEN@github.com/$REPO_PATH.git" /var/www
    else
        # Clone without token
        git clone "$REPO_URL" /var/www
    fi
    
    echo "Repository cloned to /var/www/app"
else
    mkdir -p /var/www/app
    echo "Created empty directory at /var/www/app"
fi

# Create Nginx site configuration based on app type
echo "Creating Nginx site configuration..."
cat > /etc/nginx/sites-available/default.conf << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/app;
    index index.html index.htm index.php;
    
    server_name _;
    
    location / {
        try_files \$uri \$uri/ =404;
EOF

case "$APP_TYPE" in
    laravel)
        cat >> /etc/nginx/sites-available/default.conf << 'EOF'
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
    }
EOF
        ;;
    node)
        cat >> /etc/nginx/sites-available/default.conf << 'EOF'
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
EOF
        ;;
    python)
        cat >> /etc/nginx/sites-available/default.conf << 'EOF'
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
EOF
        ;;
    go)
        cat >> /etc/nginx/sites-available/default.conf << 'EOF'
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
EOF
        ;;
esac

cat >> /etc/nginx/sites-available/default.conf << 'EOF'
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/

# Step 6: Docker setup
echo "===== Step 6: Docker setup ====="
echo "Do you want to set up Docker and Docker Compose?"
if confirm "Set up Docker"; then
    echo "Installing Docker..."
    apk add docker
    rc-update add docker boot
    service docker start
    
    echo "Installing Docker Compose dependencies..."
    apk add py3-pip gcc python3-dev musl-dev libffi-dev openssl-dev
    
    echo "Installing Docker Compose..."
    pip3 install docker-compose
    
    echo "Do you want to run docker-compose now?"
    if confirm "Run docker-compose"; then
        cd /var/www/app
        if [ -f "docker-compose.yml" ]; then
            docker-compose up -d
            echo "Docker Compose started successfully"
        else
            echo "No docker-compose.yml file found in the repository"
        fi
    fi
fi

# Step 7: Firewall setup
echo "===== Step 7: Setting up firewall ====="
echo "Installing and configuring firewall..."
apk add iptables
rc-update add iptables

# Configure basic firewall rules
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Save firewall rules
/etc/init.d/iptables save

# Step 8: Let's Encrypt setup
echo "===== Step 8: Setting up Let's Encrypt ====="
echo "Do you want to set up SSL with Let's Encrypt?"
if confirm "Set up Let's Encrypt"; then
    apk add certbot certbot-nginx
    
    echo "Enter your domain name (e.g., example.com):"
    read -r DOMAIN_NAME
    
    echo "Setting up Let's Encrypt for $DOMAIN_NAME..."
    certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email webmaster@"$DOMAIN_NAME"
    
    # Set up auto-renewal
    echo "Setting up automatic certificate renewal..."
    echo "0 3 * * * certbot renew --quiet" | crontab -
    
    echo "Let's Encrypt SSL certificate installed and auto-renewal configured"
fi

# Step 9: Start script
echo "===== Step 9: Application startup ====="
echo "Do you have a start script to run?"
if confirm "Run start script"; then
    echo "Enter the path to your start script (relative to /var/www/app):"
    read -r START_SCRIPT
    
    if [ -f "/var/www/app/$START_SCRIPT" ]; then
        echo "Making script executable..."
        chmod +x "/var/www/app/$START_SCRIPT"
        
        echo "Running start script..."
        cd /var/www/app
        "./$START_SCRIPT"
        
        # Create a service to run the start script on boot
        echo "Do you want to run this script on system startup?"
        if confirm "Run on startup"; then
            cat > /etc/local.d/webapp.start << EOF
#!/bin/sh
cd /var/www/app
./$START_SCRIPT
EOF
            chmod +x /etc/local.d/webapp.start
            rc-update add local default
            echo "Start script will run on system boot"
        fi
    else
        echo "Start script not found at /var/www/app/$START_SCRIPT"
    fi
else
    echo "No start script specified"
fi

# Restart Nginx to apply changes
service nginx restart

echo "===== Setup Complete ====="
echo "Your $APP_TYPE application has been set up successfully!"
echo "Web server is running at http://$(hostname -I | awk '{print $1}')"