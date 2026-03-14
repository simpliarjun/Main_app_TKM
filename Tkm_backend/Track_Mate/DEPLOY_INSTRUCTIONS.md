# TrackMate Backend — AWS Deployment Guide

Follow these steps in order. Do not skip any step.

---

## STEP 1 — Fill In Your API Keys

Open this file and fill in all the placeholders:

```
C:\Users\Arjun Gupta\Desktop\Tkm_backend\Track_Mate\.env.production
```

Replace every line that says `<<<...>>>` with your actual values:

| Variable | Where to get it |
|---|---|
| `DJANGO_SECRET_KEY` | Run in PowerShell: `python -c "import secrets; print(secrets.token_urlsafe(60))"` |
| `DB_PASSWORD` | Make up any strong password (e.g. `Trackmate@2024!`) |
| `GOOGLE_MAPS_API_KEY` | Google Cloud Console → Credentials |
| `GOOGLE_GEOCODING_API_KEY` | Google Cloud Console → Credentials |
| `GOOGLE_DIRECTIONS_API_KEY` | Google Cloud Console → Credentials |

Email password is already filled in (unchanged).

---

## STEP 2 — Launch EC2 Instance on AWS

1. Go to [AWS Console](https://console.aws.amazon.com) → **EC2** → **Launch Instance**
2. Fill in these settings:

   | Setting | Value |
   |---|---|
   | Name | `trackmate-backend` |
   | AMI | **Ubuntu Server 22.04 LTS** (Free tier eligible) |
   | Instance type | `t2.micro` (free tier) or `t3.small` |
   | Key pair | Select the key pair matching `TRACKMATE-BACKEND-KEY.pem` |
   | Network | Default VPC |

3. Under **Network Settings** → **Edit**, add these inbound rules to the security group:

   | Type | Port | Source |
   |---|---|---|
   | SSH | 22 | My IP |
   | HTTP | 80 | 0.0.0.0/0 |

4. Click **Launch Instance**

5. Wait ~2 minutes, then go to **Instances** and copy the **Public IPv4 address**.
   It will look like: `13.127.xx.xx`

   > **Write it down — you need it in Steps 3, 4, and 5.**

---

## STEP 3 — Fix PEM Key Permissions (PowerShell — run once)

Open **PowerShell as Administrator** and run:

```powershell
icacls "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" /inheritance:r /grant:r "%USERNAME%:R"
```

---

## STEP 4 — Upload Project Files to EC2

Open **PowerShell** (normal, not Admin) and run:

> Replace `YOUR_EC2_IP` with the IP from Step 2.

```powershell
scp -i "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" -r "C:\Users\Arjun Gupta\Desktop\Tkm_backend\Track_Mate" ubuntu@YOUR_EC2_IP:/home/ubuntu/
```

When prompted `Are you sure you want to continue connecting?` type `yes`.

---

## STEP 5 — Upload Production .env to EC2

```powershell
scp -i "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" "C:\Users\Arjun Gupta\Desktop\Tkm_backend\Track_Mate\.env.production" ubuntu@YOUR_EC2_IP:/home/ubuntu/Track_Mate/.env
```

---

## STEP 6 — SSH Into the Server

```powershell
ssh -i "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" ubuntu@YOUR_EC2_IP
```

---

## STEP 7 — Run the Deployment Script (on the server)

Once you are SSH'd in, run:

```bash
chmod +x /home/ubuntu/Track_Mate/deploy.sh
bash /home/ubuntu/Track_Mate/deploy.sh
```

This will automatically:
- Install Python 3, PostgreSQL, Nginx
- Create the database and user
- Install all Python dependencies
- Run Django migrations
- Set up Nginx as a reverse proxy
- Set up Gunicorn as a background service

Wait for it to finish. You will see **"Deployment Complete!"** at the end.

---

## STEP 8 — Test Your API

Open your browser or Postman and visit:

```
http://YOUR_EC2_IP/api/
```

Or test with:

```powershell
curl http://YOUR_EC2_IP/api/auth/signup/
```

---

## Useful Commands (run on the server after SSH)

| Task | Command |
|---|---|
| Check if app is running | `sudo systemctl status trackmate` |
| View live app logs | `sudo journalctl -u trackmate -f` |
| Restart app | `sudo systemctl restart trackmate` |
| View Nginx errors | `sudo tail -f /var/log/nginx/error.log` |
| Restart Nginx | `sudo systemctl restart nginx` |

---

## Redeployment (when you update code)

If you update the code and want to redeploy:

```powershell
# 1. Upload new files from your PC (replace YOUR_EC2_IP)
scp -i "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" -r "C:\Users\Arjun Gupta\Desktop\Tkm_backend\Track_Mate" ubuntu@YOUR_EC2_IP:/home/ubuntu/

# 2. SSH in and restart
ssh -i "C:\Users\Arjun Gupta\Desktop\KEYSS\TRACKMATE-BACKEND-KEY.pem" ubuntu@YOUR_EC2_IP
```

```bash
# On the server:
cd /home/ubuntu/Track_Mate
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
deactivate
sudo systemctl restart trackmate
```
