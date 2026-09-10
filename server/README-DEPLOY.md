# Deploying the Codenames server

## 1. Upload
Copy the whole `server/` folder to your Linux server, e.g.:
```
scp -r server root@YOUR_SERVER_IP:/root/codenames-server
```

## 2. Install & run
```bash
ssh root@YOUR_SERVER_IP
cd /root/codenames-server
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install
npm install -g pm2
pm2 start server.js --name codenames
pm2 startup && pm2 save
```

## 3. (Recommended) Put it behind Nginx + HTTPS
```bash
apt install -y nginx certbot python3-certbot-nginx
# point an Nginx server block at 127.0.0.1:3000, then:
certbot --nginx -d yourdomain.ir
```

## 4. Test it
Visit `http://YOUR_SERVER_IP:3000/health` (or `https://yourdomain.ir/health`
if you set up Nginx) — you should see `{"ok":true,"rooms":0}`.

## 5. Point the app at it
In `lib/main.dart`, find this line near the top:
```dart
const String kServerUrl = 'http://YOUR_SERVER_IP_OR_DOMAIN:3000';
```
Replace it with your real server address, then rebuild the app.
