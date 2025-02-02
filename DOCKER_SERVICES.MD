# Docker Services

## Pi-hole
`docker run -d --name pihole \
-e ServerIP=192.168.100.10 \
-e WEBPASSWORD=paulrita7 \
-e TZ=Asia/Kuala_Lumpur \
-e DNS1=127.17.0.1 -e DNS2=1.1.1.1 -e DNS3=1.0.0.1 \
-p 80:80 -p 53:53/tcp -p 53:53/udp -p 443:443 \
--restart=unless-stopped \
pihole/pihole:latest`

## AdGuard Home
`docker run --name adguardhome \
--restart unless-stopped \
-v /my/own/workdir:/opt/adguardhome/work \
-v /my/own/confdir:/opt/adguardhome/conf \
-p 53:53/tcp -p 53:53/udp \
-p 67:67/udp -p 68:68/udp \
-p 80:80/tcp -p 443:443/tcp -p 443:443/udp \
-p 3000:3000/tcp -p 853:853/tcp \
-p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
-p 5443:5443/tcp -p 5443:5443/udp \
-d adguard/adguardhome`

## MySQL

`docker run -d --name mysql \
-e MYSQL_ROOT_PASSWORD=yourpassword \
-e MYSQL_DATABASE=yourdatabase \
-e MYSQL_USER=youruser \
-e MYSQL_PASSWORD=yourpassword \
-p 3306:3306 \
--restart unless-stopped \
mysql:latest`