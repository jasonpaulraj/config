# Deploying a React App on Oracle Linux with NGINX

This guide provides step-by-step instructions for deploying a React app on an Oracle Linux server with NGINX. The setup will allow you to serve the static files from your React app’s `build` folder and configure NGINX as the web server.

## Prerequisites

- An Oracle Linux server (7 or newer)
- Root or sudo access to the server
- React app ready for deployment

## Steps to Deploy the React App

### 1. Build the React Application

First, ensure your React app is ready for deployment by building it.

```bash
npm run build
```

This will generate a `build` folder containing all the static files required to deploy the app.

### 2. Transfer the Build Folder to the Server

Use `scp` or another file transfer tool to upload the `build` folder to the server.

```bash
scp -r build/ user@your-server-ip:/home/user
```

Replace `user` and `your-server-ip` with your actual server username and IP address.

### 3. Install NGINX

On Oracle Linux, you may need to use `yum` as the package manager (instead of `dnf`).

```bash
sudo yum install nginx -y
```

### 4. Start and Enable NGINX

After installing NGINX, start and enable it to ensure it runs on every server reboot.

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 5. Configure the Firewall

If `firewalld` is enabled on your server, allow HTTP and HTTPS traffic.

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 6. Set Up NGINX to Serve the React Build Folder

1. Move the `build` folder to a web-accessible directory (like `/var/www`):

    ```bash
    sudo mv /home/user/build /var/www/my-react-app
    ```

2. Create a new NGINX configuration file for the React app:

    ```bash
    sudo nano /etc/nginx/conf.d/my-react-app.conf
    ```

3. Add the following configuration to the file:

    ```nginx
    server {
        listen 80;
        server_name your-domain.com;  # Replace with your domain or server IP

        root /var/www/my-react-app;

        index index.html index.htm;

        location / {
            try_files $uri /index.html;
        }
    }
    ```

    - **Note**: Replace `your-domain.com` with your actual domain or server IP.
    - The `try_files $uri /index.html;` directive ensures that all requests are redirected to `index.html` to support React’s client-side routing.

4. Test the NGINX configuration to ensure there are no syntax errors:

    ```bash
    sudo nginx -t
    ```

5. Restart NGINX to apply the changes:

    ```bash
    sudo systemctl restart nginx
    ```

### 7. Access Your React Application

Your React app should now be accessible at `http://your-server-ip` or `http://your-domain.com`. 

If there are any issues, check the NGINX logs for troubleshooting:

```bash
cat /var/log/nginx/error.log
```

## Additional Information

- **Oracle Linux Version**: If you’re on Oracle Linux 8 or higher, `dnf` may be available as the package manager. In that case, replace `yum` with `dnf` in the commands.
- **React Routing**: The NGINX configuration is set up to handle client-side routing, which is common in React applications.
- **Firewall**: Adjust firewall settings according to your server’s security requirements.

## Conclusion

This guide covers the essentials to deploy a React application on an Oracle Linux server with NGINX. With this setup, you can serve your static React files and allow client-side routing through NGINX.
