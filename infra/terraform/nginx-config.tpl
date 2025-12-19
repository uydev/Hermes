# Nginx configuration for Hermes backend
# This file should be placed at: /etc/nginx/sites-available/hermes-backend
# Then symlinked: sudo ln -s /etc/nginx/sites-available/hermes-backend /etc/nginx/sites-enabled/
# After SSL setup, certbot will modify this file automatically

# HTTP -> HTTPS redirect
server {
    listen 80;
    server_name ${domain_name};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name ${domain_name};

    # SSL certificates (will be configured by certbot)
    # ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

    # SSL configuration (certbot will add this)
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Proxy to backend Docker container
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
