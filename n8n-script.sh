#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "Welcome to the n8n installation script!"

# OS Updates
echo "Updating operating system..."
sudo apt update && sudo apt upgrade -y

# Prerequisites
echo "Installing Node.js..."
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install NGINX
echo "Installing NGINX server and SSL configuration..."
sudo apt install nginx -y

#Crating nginx config file
echo "NGINX Configuration file is created"
sudo touch /etc/nginx/sites-available/n8n.conf

# Configure NGINX
echo "Configuring NGINX..."
echo "Please enter the domain name you want to use for n8n (e.g. example.com):"
read domain_name
server_name="server_name $domain_name;"
cat > /etc/nginx/sites-available/n8n.conf <<EOF
server {
    server_name $server_name
    listen 80;
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/n8n.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Install PM2
echo "Installing PM2..."
sudo npm install pm2 -g

# Install n8n
echo "Installing n8n..."
sudo npm install n8n -g

# Start n8n with pm2
echo "n8n Started with pm2"
pm2 start n8n

# Setup auto-start n8n on machine restart
echo "Setting up n8n to start automatically on machine restart..."
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER

# Pm2 save
echo "pm2 will auto start on system restart"
pm2 save

# Create pm2 config
echo "Configuring n8n..."
echo "Do you want to use the same domain ($domain_name) for n8n, webhook URL, and editor URL? (y/n)"
read same_domain
if [ "$same_domain" = "y" ]; then
    n8n_host=$domain_name
    webhook_url="https://$domain_name/"
    editor_base_url="https://$domain_name/"
else
    echo "Please enter the domain name you want to use for n8n (e.g. example.com):"
    read n8n_host
    webhook_url="https://$n8n_host/"
    editor_base_url="https://$n8n_host/"
fi

echo "Please enter the username you want to use for n8n basic authentication:"
read n8n_username
echo "Please enter the password you want to use for n8n basic authentication:"
read n8n_password

echo "PM2 Configuration file is created"
sudo touch ./ecosystem.config.js

cat > ~/ecosystem.config.js <<EOF
module.exports = {
    apps : [{
        name   : "n8n",
        env: {
            N8N_PROTOCOL: "https",
            TZ:"Asia/Kolkata",
            GENERIC_TIMEZONE: "Asia/Kolkata",
            N8N_USER_MANAGEMENT_DISABLED: true,
            N8N_BASIC_AUTH_ACTIVE: true,
            N8N_BASIC_AUTH_USER: "$n8n_username",
            N8N_BASIC_AUTH_PASSWORD: "$n8n_password",
            N8N_HOST: "$n8n_host",
            WEBHOOK_URL: "$webhook_url",
            N8N_EDITOR_BASE_URL: "$editor_base_url",
            N8N_ENDPOINT_WEBHOOK: "prod/v1",
            N8N_ENDPOINT_WEBHOOK_TEST: "test/v1",
            N8N_METRICS: true,
        }
   }]
}
EOF

# Start n8n with pm2 config
pm2 start ecosystem.config.js

# Allow bothudp and tcp for `Nginx Full`, `OpenSSH` & `5678,443,80` to be accessed from the internet
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 5678/tcp
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 5678/udp
sudo ufw allow 443/udp
sudo ufw allow 80/udp
