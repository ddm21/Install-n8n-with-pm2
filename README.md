# Install-n8n-with-pm2

Set up n8n via PM2

### OS Updates
Before doing anything else, update your operating system by running these two commands:
```
sudo apt update && sudo apt upgrade -y
```
#
## Prerequisites
To run n8n via PM2, you need to have the following software installed:
#
### Install Node.js
Add the NodeSource APT repository for Node 16
```
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash &&
sudo apt-get install nodejs -y
```
#
### Install NGINX
NGINX server and the SSL configuration requires
```
sudo apt install nginx -y
```
#
### Check Status of NGINX (optional)
```
sudo systemctl status nginx
```
#
### Configure NGINX
```
cd /etc/nginx/sites-available/ &&
sudo nano n8n.conf
```
Now insert a copy of the below example configuration and replace
```
server {
    server_name n8n.domain.tld;
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
```
#
Now linking the file we have just created
```
sudo ln -s /etc/nginx/sites-available/n8n.conf /etc/nginx/sites-enabled/ &&
sudo nginx -t &&
sudo systemctl reload nginx
```
#
### Install PM2
```
sudo npm install pm2 -g
```
### Install n8n
```
sudo npm install n8n -g
```
#
### update
```
sudo npm update -g  n8n
```
#
### Start n8n via PM2
```
pm2 start n8n
```
#
### Setup auto-start n8n on machine restart
```
pm2 startup
```
#
### Restart the n8n service
```
pm2 restart n8n
```
#
### pm2 config
create pm2 config with `pm2 init simple` replce with below code
```
module.exports = {
    apps : [{
        name   : "n8n",
        env: {
            // N8N_EMAIL_MODE: "smtp",
            // N8N_SMTP_HOST: "smtp.gmail.com",
            // N8N_SMTP_PORT: "465",
            // N8N_SMTP_USER: "admin@admin.com",
            // N8N_SMTP_PASS: "password",
            // N8N_SMTP_SSL: "true",
            N8N_PROTOCOL: "https",
            TZ:"Asia/Kolkata",
            GENERIC_TIMEZONE: "Asia/Kolkata",
            N8N_USER_MANAGEMENT_DISABLED: true,
            N8N_BASIC_AUTH_ACTIVE: true,
            N8N_BASIC_AUTH_USER: "admin",
            N8N_BASIC_AUTH_PASSWORD: "password",
            N8N_HOST: "n8n.domain.tld",
            WEBHOOK_URL: "https://n8n.domain.tld/",
            N8N_EDITOR_BASE_URL: "https://n8n.domain.tld/",
            N8N_ENDPOINT_WEBHOOK: "prod/v1",
            N8N_ENDPOINT_WEBHOOK_TEST: "test/v1",
            N8N_METRICS: true,
        }
    }]
}
#
```
### Start with pm2 config
```
sudo pm2 start ecosystem.config.js
```

### Start with pm2 with update config
```
sudo pm2 restart ecosystem.config.js --update-env
```
#
We are now ready to configure UFW. First make sure it knows about all your applications by running the below command. It should return `Nginx Full` and `OpenSSH` among the available applications.
```
sudo ufw app list
```
#
Now allow both `Nginx Full` and `OpenSSH` to be accessed from the internet:
```
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 5678
```
#
### Enable firewall
```
sudo ufw enable
```
