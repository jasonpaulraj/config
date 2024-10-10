# Step 2: Copy Files to the Server with SCP

Use `scp` to copy the `build` folder to your Linux server. Adjust `<username>`, `<server_ip>`, and `<target_directory>` as needed.

```bash
scp -r build <username>@<server_ip>:/<target_directory>
```

For example:

```bash
scp -r build user@192.168.1.10:/var/www/myapp
```

This will copy the contents of the `build` folder to the `/var/www/myapp` directory on your server.
