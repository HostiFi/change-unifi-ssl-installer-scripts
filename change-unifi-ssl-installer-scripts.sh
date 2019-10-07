#!/bin/bash
while getopts e:d: option
do
case "${option}"
in
e) EMAIL=${OPTARG};;
d) HOSTNAMEVAR=${OPTARG};;
esac
done
echo $EMAIL;
echo $HOSTNAMEVAR;

apt auto-remove -y
modprobe ip_tables
echo 'ip_tables' >> /etc/modules

echo "Removing Apache2"
apt-get remove apache2 -y

echo "Installing NGINX"
apt-get install nginx-light -y

echo "Installing Let's Encrypt"
apt-get update -y
apt-get install python-certbot-nginx -t stretch-backports -y

echo "Getting cert"
wget https://raw.githubusercontent.com/HostiFi/unifi-lets-encrypt-ssl-updater/master/unifi-lets-encrypt-ssl-updater.sh
chmod +x /root/unifi-lets-encrypt-ssl-updater.sh
/bin/bash /root/unifi-lets-encrypt-ssl-updater.sh -d $HOSTNAMEVAR -e $EMAIL

echo "Creating Let's Encrypt cron"
crontab -l > /root/letsencryptcron
echo "0 23 * * * /bin/bash /root/unifi-lets-encrypt-ssl-importer.sh -d $HOSTNAMEVAR" >> /root/letsencryptcron
crontab /root/letsencryptcron
rm /root/letsencryptcron
crontab -l > /root/certbotcron
echo "0 22 * * * /usr/bin/certbot renew" >> /root/certbotcron
crontab /root/certbotcron
rm /root/certbotcron

echo "Removing old SSL script"
rm /root/unifi-ssl.sh

echo "Creating firewall rules"
iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
iptables -A INPUT -i ens3 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8443 -j ACCEPT
iptables -A INPUT -p udp --dport 3478 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8843 -j ACCEPT
iptables -A INPUT -j DROP
iptables -A OUTPUT -o ens3 -j ACCEPT

echo "Saving firewall rules"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install iptables-persistent netfilter-persistent -y

netfilter-persistent save

echo "Configuring NGINX to forward HTTP to HTTPS"
echo "server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}" > /etc/nginx/sites-available/redirect
ln -s /etc/nginx/sites-available/redirect /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

echo "Restarting services"
systemctl restart nginx
systemctl restart unifi

echo "Done!"
