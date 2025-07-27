
# Challenge Técnico - Automation Specialist

## Parte 1: Infraestructura - N8N Self-hosted en Google Cloud

### Objetivo

Desplegar una instancia funcional y segura de N8N, autoalojada en Google Cloud, con:

- Branding personalizado (logo y colores de ATOM)
- Acceso desde dominio público
- Protección mediante HTTPS

### Requisitos Previos

- Cuenta activa en Google Cloud Platform
- Dominio público (se utilizó DuckDNS)
- Acceso SSH a una VM con Ubuntu/Debian
- Usuario con permisos sudo
- Puerto 5678 abierto en el firewall de GCP

### Paso 1: Crear una VM en Google Cloud

1. Ir a: Compute Engine > Instancias de VM
2. Crear una nueva instancia:
   - Imagen: Debian 12 (debian-12-bookworm-v20250709)
   - Habilitar acceso HTTP/HTTPS
   - Agregar regla de firewall personalizada para el puerto 5678
3. Conectarse vía SSH

### Paso 2: Instalar Docker y Docker Compose

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
sudo apt install docker-compose -y
```

### Paso 3: Crear el archivo docker-compose.yml

```bash
mkdir ~/n8n && cd ~/n8n
nano docker-compose.yml
```

Contenido del archivo:

```yaml
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
```

```bash
sudo chown -R 1000:1000 ./n8n_data
```

### Paso 4: Levantar el contenedor

```bash
sudo docker-compose up -d
```

### Acceso

Abrir navegador en: http://[TU-IP-PÚBLICA]:5678

### Paso 5: Configurar HTTPS con Nginx + Let's Encrypt

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

Crear archivo de configuración Nginx:

```bash
sudo nano /etc/nginx/sites-available/n8n
```

Contenido del archivo:

```nginx
server {
    server_name n8natom.duckdns.org;

    location = /logo-inject-n8n.js {
        root /var/www/html;
        default_type application/javascript;
    }

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Accept-Encoding "";

        sub_filter '</head>' '<script src="/logo-inject-n8n.js"></script></head>';
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
    if ($host = n8natom.duckdns.org) {
        return 301 https://$host$request_uri;
    }

    listen 80;
    server_name n8natom.duckdns.org;
    return 404;
}
```

Activar el sitio y reiniciar Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Obtener certificado SSL con Certbot:

```bash
sudo certbot --nginx -d n8natom.duckdns.org
```

### Personalización – Logo ATOM

Crear el archivo logo-inject-n8n.js:

```bash
sudo mkdir -p /var/www/html
sudo nano /var/www/html/logo-inject-n8n.js
```

Contenido del archivo:

```javascript
document.addEventListener("DOMContentLoaded", () => {
  const logo = document.querySelector("img[src='/logo.png']");
  if (logo) {
    logo.src = "https://atom.yourcdn.com/logo.png";
  }
  document.documentElement.style.setProperty('--color-primary', '#00BFA6');
});
```

### Verificación Final

- N8N accesible en: https://n8natom.duckdns.org
- Certificado SSL válido
- Interfaz personalizada con logo ATOM
- Usuario: correoPrueba@gmail.com
- Contraseña: ContraseñaSeguraAsignar (Autenticación básica)

### Archivos Entregables

- setup-n8n.sh: Script de instalación completo

Para ejecutarlo:

```bash
chmod +x setup-n8n.sh
./setup-n8n.sh
```

- Capturas de pantalla de N8N funcionando
- URL de acceso: https://n8natom.duckdns.org
