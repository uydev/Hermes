#!/bin/bash
set -e

# Update system
apt-get update
apt-get install -y docker.io docker-compose nginx certbot python3-certbot-nginx curl

# Start Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create directory for backend
mkdir -p /opt/hermes-backend

# Configure Nginx
cat > /etc/nginx/sites-available/hermes-backend <<NGINX_CONFIG
server {
    listen 80;
    server_name ${domain_name};

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_CONFIG

# Enable Nginx site
ln -sf /etc/nginx/sites-available/hermes-backend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and start Nginx
nginx -t
systemctl start nginx
systemctl enable nginx

echo "✅ Nginx configured and started with server_name: ${domain_name}"
