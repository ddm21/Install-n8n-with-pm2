#!/bin/bash

set -e

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

# Checklist: Configure NGINX
echo "Checklist: Configure NGINX"
echo "Please enter the domain name or static IP you want to use for n8n (e.g. example.com or 192.168.1.100):"
read domain_or_ip
server_name="server_name $domain_or_ip;"
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
echo "Starting n8n with pm2..."
pm2 start n8n

# Setup auto-start n8n on machine restart
echo "Setting up n8n to start automatically on machine restart..."
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER

# Pm2 save
echo "Saving pm2 configuration..."
pm2 save

# Checklist: Create pm2 config
echo "Checklist: Create pm2 config"
echo "Do you want to use HTTPS for n8n? (y/n)"
read use_https

if [ "$use_https" = "y" ]; then
    protocol="https"
    echo "Please enter the domain name or static IP associated with the SSL certificate:"
    read ssl_domain_or_ip
    
    if [[ $ssl_domain_or_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IP address entered, skipping DNS record check
        echo "IP address entered. Skipping DNS record check."
    else
        # Domain name entered, check DNS record existence
        if ! dig +short $ssl_domain_or_ip; then
            echo "DNS record not found for the domain. Changing protocol to HTTP."
            protocol="http"
        else
            echo "Installing self-signed Let's Encrypt certificate..."
            sudo apt-get install certbot -y
            sudo certbot certonly --standalone --agree-tos --non-interactive --preferred-challenges http -d $ssl_domain_or_ip
            
            # Check if certificate installation was successful
            if [ ! -f "/etc/letsencrypt/live/$ssl_domain_or_ip/fullchain.pem" ]; then
                echo "Error: Failed to install SSL certificate. Reverting to HTTP protocol."
                protocol="http"
            fi
        fi
    fi
else
    protocol="http"
fi

echo "Please enter the username you want to use for n8n basic authentication:"
read n8n_username
echo "Please enter the password you want to use for n8n basic authentication:"
read n8n_password

if [ "$protocol" = "https" ]; then
    webhook_url="$protocol://$ssl_domain_or_ip/"
    editor_base_url="$protocol://$ssl_domain_or_ip/"
else
    webhook_url="$protocol://$domain_or_ip/"
    editor_base_url="$protocol://$domain_or_ip/"
fi

cat > ~/ecosystem.config.js <<EOF
module.exports = {
    apps : [{
        name   : "n8n",
        env: {
            N8N_PROTOCOL: "$protocol",
            TZ:"Asia/Kolkata",
            GENERIC_TIMEZONE: "Asia/Kolkata",
            N8N_USER_MANAGEMENT_DISABLED: true,
            N8N_BASIC_AUTH_ACTIVE: true,
            N8N_BASIC_AUTH_USER: "$n8n_username",
            N8N_BASIC_AUTH_PASSWORD: "$n8n_password",
            N8N_HOST: "$domain_or_ip",
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

# Allow both udp and tcp for `Nginx Full`, `OpenSSH` & `5678,443,80` to be accessed from the internet
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 5678/tcp
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 5678/udp
sudo ufw allow 443/udp
sudo ufw allow 80/udp
