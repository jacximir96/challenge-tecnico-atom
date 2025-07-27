#!/bin/bash

# Challenge Técnico - Automation Specialist
# Script de instalación automática de N8N en Google Cloud VM

echo "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "Instalando Docker..."
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker

echo "Instalando Docker Compose..."
sudo apt install docker-compose -y

echo "Creando carpeta para N8N..."
mkdir -p ~/n8n && cd ~/n8n

echo "Generando archivo docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: "3"

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=n8natom.duckdns.org
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=https://n8natom.duckdns.org
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=correoPrueba@gmail.com
      - N8N_BASIC_AUTH_PASSWORD=ContraseñaSeguraAsignar
      - N8N_SECURE_COOKIE=false
      - N8N_RUNNERS_ENABLED=true
    volumes:
      - ./n8n_data:/home/node/.n8n
EOF

echo "Asignando permisos al volumen de datos..."
sudo chown -R 1000:1000 ./n8n_data

echo "Levantando contenedor de N8N..."
sudo docker-compose up -d

echo "Instalando NGINX y Certbot..."
sudo apt install nginx certbot python3-certbot-nginx -y

echo "Creando configuración NGINX para N8N..."
sudo bash -c 'cat <<EOF > /etc/nginx/sites-available/n8n
server {
    server_name n8natom.duckdns.org;

    location = /logo-inject-n8n.js {
        root /var/www/html;
        default_type application/javascript;
    }

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Accept-Encoding "";

        sub_filter "</head>" "<script src=/logo-inject-n8n.js></script></head>";
        sub_filter_once off;
        sub_filter_types text/html;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/n8natom.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8natom.duckdns.org/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    if (\$host = n8natom.duckdns.org) {
        return 301 https://\$host\$request_uri;
    }

    listen 80;
    server_name n8natom.duckdns.org;
    return 404;
}
EOF'

echo "Habilitando sitio en NGINX..."
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

echo "Solicitando certificado SSL con Certbot..."
sudo certbot --nginx -d n8natom.duckdns.org

echo "Instalación y configuración completa."
echo "Accede a: https://n8natom.duckdns.org"
