# Step 3: Set Up a Web Server on Port 80

You can use either Nginx or Apache to serve the static files. Here’s how to do it with Nginx.

## Install Nginx (if not installed)

On Ubuntu or Debian-based systems:

```bash
sudo apt update
sudo apt install nginx
```

## Configure Nginx to Serve Your React App

1. Create an Nginx configuration file for your React app:

    ```bash
    sudo nano /etc/nginx/sites-available/myapp
    ```

2. Add the following configuration:

    ```nginx
    server {
        listen 80;
        server_name your_domain_or_ip;

        root /var/www/myapp;
        index index.html;

        location / {
            try_files $uri /index.html;
        }
    }
    ```

3. Enable the configuration by creating a symlink to `sites-enabled`:

    ```bash
    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
    ```

4. Test the configuration and reload Nginx:

    ```bash
    sudo nginx -t
    sudo systemctl reload nginx
    ```
