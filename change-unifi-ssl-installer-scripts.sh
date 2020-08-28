#!/bin/bash
# parse domains to an array
#!/bin/bash
# parse domains to an array
while getopts e:d: option; do
  case $option in
    "d") DOMAINS+=("$OPTARG");;
    "e") EMAIL=${OPTARG};;
  esac
done
echo $EMAIL;
for DOMAIN in "${DOMAINS[@]}"; do
  stringprefix=" -d "
  stringpostfix=" "
  DOMAINSTR+=$stringprefix$DOMAIN$stringpostfix
done
echo $DOMAINSTR;

apt-get autoremove -y
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
wget https://raw.githubusercontent.com/HostiFi/unifi-lets-encrypt-ssl-updater/master/unifi-lets-encrypt-ssl-updater.sh -O unifi-lets-encrypt-ssl-updater.sh
chmod +x /root/unifi-lets-encrypt-ssl-updater.sh
/bin/bash /root/unifi-lets-encrypt-ssl-updater.sh $DOMAINSTR -e $EMAIL

echo "Creating Let's Encrypt cron"
crontab -l > /root/letsencryptcron
echo "0 23 * * * /bin/bash /root/unifi-lets-encrypt-ssl-importer.sh -d ${DOMAINS[0]}" >> /root/letsencryptcron
crontab /root/letsencryptcron
rm /root/letsencryptcron
crontab -l > /root/certbotcron
echo "0 22 * * * /usr/bin/certbot renew" >> /root/certbotcron
crontab /root/certbotcron
rm /root/certbotcron

echo "Removing old SSL script"
rm /root/unifi-ssl.sh

echo "Restarting services"
systemctl restart nginx
systemctl restart unifi

echo "Done!"
