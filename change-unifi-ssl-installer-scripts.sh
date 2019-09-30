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

certbot --nginx --email $EMAIL --agree-tos --no-eff-email --domain $HOSTNAMEVAR --no-redirect
wget https://raw.githubusercontent.com/HostiFi/unifi-lets-encrypt-ssl-updater/master/unifi-lets-encrypt-ssl-updater.sh
chmod +x /root/unifi-lets-encrypt-ssl-importer.sh
/root/unifi-lets-encrypt-ssl-importer.sh -d $HOSTNAMEVAR

echo "Creating Let's Encrypt cron"
crontab -l > /root/letsencryptcron
echo "0 23 * * * /bin/bash /root/unifi-lets-encrypt-ssl-importer.sh -d $HOSTNAMEVAR" >> /root/letsencryptcron
crontab /root/letsencryptcron
rm /root/letsencryptcron

# Remove old script
rm /root/unifi-ssl.sh
