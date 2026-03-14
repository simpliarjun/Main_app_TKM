#!/bin/bash
# =============================================================
#  TrackMate Backend — EC2 Deployment Script
#  Run this on the EC2 server after uploading the project files.
#  Usage:  bash /home/ubuntu/Track_Mate/deploy.sh
# =============================================================

set -e

PROJECT_DIR="/home/ubuntu/Track_Mate"
VENV_DIR="$PROJECT_DIR/venv"
ENV_FILE="$PROJECT_DIR/.env"

echo ""
echo "============================================="
echo "  TrackMate Backend — Starting Deployment"
echo "============================================="

# ── 1. System update and packages ────────────────────────────
echo ""
echo "[1/8] Installing system packages..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx libpq-dev

# ── 2. PostgreSQL setup ───────────────────────────────────────
echo ""
echo "[2/8] Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Load env vars to get DB credentials
set -a
source "$ENV_FILE"
set +a

sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# ── 3. Python virtual environment ────────────────────────────
echo ""
echo "[3/8] Setting up Python virtual environment..."
cd "$PROJECT_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt

# ── 4. Django migrations and static files ────────────────────
echo ""
echo "[4/8] Running Django migrations..."
python manage.py migrate

echo ""
echo "[5/8] Collecting static files..."
python manage.py collectstatic --noinput

deactivate

# ── 5. Nginx configuration ────────────────────────────────────
echo ""
echo "[6/8] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/trackmate > /dev/null << 'NGINX_CONF'
server {
    listen 80;
    server_name _;

    client_max_body_size 20M;

    location /static/ {
        alias /home/ubuntu/Track_Mate/staticfiles/;
    }

    location /media/ {
        alias /home/ubuntu/Track_Mate/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_CONF

sudo ln -sf /etc/nginx/sites-available/trackmate /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Ensure Gunicorn log files exist and are writable by the service user.
sudo install -o ubuntu -g ubuntu -m 664 /dev/null /var/log/trackmate_access.log
sudo install -o ubuntu -g ubuntu -m 664 /dev/null /var/log/trackmate_error.log

# ── 6. Gunicorn systemd service ───────────────────────────────
echo ""
echo "[7/8] Configuring Gunicorn systemd service..."
sudo tee /etc/systemd/system/trackmate.service > /dev/null << GUNICORN_SERVICE
[Unit]
Description=TrackMate Django Backend (Gunicorn)
After=network.target postgresql.service

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/gunicorn trackmate.wsgi:application \\
    --bind 127.0.0.1:8000 \\
    --workers 3 \\
    --timeout 120 \\
    --access-logfile /var/log/trackmate_access.log \\
    --error-logfile /var/log/trackmate_error.log
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
GUNICORN_SERVICE

sudo systemctl daemon-reload
sudo systemctl restart trackmate
sudo systemctl enable trackmate

# ── 7. Fix permissions ────────────────────────────────────────
echo ""
echo "[8/8] Setting file permissions..."
sudo chown -R ubuntu:ubuntu "$PROJECT_DIR"
sudo chmod 600 "$ENV_FILE"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "============================================="
echo "  Deployment Complete!"
echo "============================================="
echo ""
echo "  Service status:"
sudo systemctl status trackmate --no-pager -l | head -20
echo ""
echo "  Nginx status:"
sudo systemctl status nginx --no-pager | head -5
echo ""
echo "  Your API is now running at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "  Useful commands:"
echo "    View app logs  :  sudo journalctl -u trackmate -f"
echo "    Restart app    :  sudo systemctl restart trackmate"
echo "    Nginx logs     :  sudo tail -f /var/log/nginx/error.log"
echo "============================================="
