
proxmox shell find ip - lxc-info -i -n 114
scp deploy_to_alpine.sh root@192.168.1.100:/root/
ssh USER@IP "/root/deploy_to_alpine.sh --app-type python"
chmod +x /root/deploy_to_alpine.sh
cd /root
./deploy_to_alpine.sh --app-type python



Undoing docker lxc promox helper script autologin #324
 Locked
tteck announced in Announcements

tteck
on Jul 9, 2022
Maintainer
This has been asked several times so I'll list the steps to undo autologin
If you don't set a root password first, you will not be able to login to the container again, ever.

set the root password sudo passwd root

remove --autologin root from /etc/systemd/system/container-getty@1.service.d/override.conf

reboot

🔄 Bonus Tip:
If you have scripts or muscle memory with docker-compose, you can create a quick alias:

bash
Copy
Edit
echo 'alias docker-compose="docker compose"' >> ~/.bashrc && source ~/.bashrc