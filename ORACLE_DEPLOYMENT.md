# Déploiement sur Oracle Cloud Free Tier

## Status
✅ **FONCTIONNE** - Déployé avec succès via SSH sur VM Compute Instance

## Vue d'ensemble

Cette branche est optimisée pour le déploiement sur Oracle Cloud Free Tier via une VM Compute Instance (VPS). Le déploiement se fait par SSH directement sur la machine virtuelle.

### Différences avec la branche `main`
- ❌ Pas de Dockerfile (déploiement direct avec Node.js)
- ✅ Configuration pour VM Ubuntu/Oracle Linux
- ✅ Installation directe de PostgreSQL et Redis sur la VM

---

## 1. Prérequis

### Compte Oracle Cloud
1. Créer un compte gratuit : https://www.oracle.com/cloud/free/
2. Le Free Tier inclut :
   - 2 VM AMD avec 1/8 OCPU et 1 GB RAM (Always Free)
   - OU 4 ARM Ampere A1 cores et 24 GB RAM (Always Free)
   - 200 GB de stockage Block Volume

### Clé SSH
Vous aurez besoin d'une paire de clés SSH pour vous connecter à la VM.

```bash
# Générer une clé SSH si vous n'en avez pas
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_cloud_key
```

---

## 2. Créer une Compute Instance

### Depuis la console Oracle Cloud :

1. **Menu** → **Compute** → **Instances** → **Create Instance**

2. **Configuration recommandée :**
   - **Name** : medusa-backend
   - **Image** : Ubuntu 22.04 (ou Oracle Linux 8)
   - **Shape** :
     - VM.Standard.A1.Flex (ARM - 4 OCPU, 24GB RAM) ⭐ RECOMMANDÉ
     - OU VM.Standard.E2.1.Micro (AMD - 1GB RAM)
   - **Network** :
     - Créer un nouveau VCN ou utiliser un existant
     - Assigner une IP publique
   - **SSH Keys** : Coller votre clé publique SSH

3. **Configurer les Security Rules (Firewall)**

   Dans **Networking** → **Virtual Cloud Networks** → Votre VCN → **Security Lists** :

   Ajouter les règles Ingress :
   ```
   Type: Custom TCP
   Source: 0.0.0.0/0
   Port: 9000 (API Medusa)

   Type: Custom TCP
   Source: 0.0.0.0/0
   Port: 7001 (Admin Medusa)

   Type: SSH
   Source: 0.0.0.0/0 (ou votre IP uniquement pour plus de sécurité)
   Port: 22
   ```

4. **Créer l'instance** → Attendre qu'elle démarre

5. **Noter l'IP publique** de votre instance

---

## 3. Connexion SSH et Configuration Initiale

```bash
# Se connecter à la VM (remplacer <IP> par l'IP publique de votre instance)
ssh -i ~/.ssh/oracle_cloud_key ubuntu@<IP_PUBLIQUE>

# OU si Oracle Linux :
ssh -i ~/.ssh/oracle_cloud_key opc@<IP_PUBLIQUE>
```

### Mettre à jour le système

```bash
sudo apt update && sudo apt upgrade -y
```

### Installer les dépendances

```bash
# Node.js 20 LTS (requis par Medusa)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Vérifier l'installation
node --version  # doit être >= 20.0.0
npm --version

# Git
sudo apt install -y git

# PM2 pour gérer le processus Node.js
sudo npm install -g pm2
```

---

## 4. Installer PostgreSQL

```bash
# Installer PostgreSQL 16
sudo apt install -y postgresql postgresql-contrib

# Démarrer PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Créer la base de données et l'utilisateur
sudo -u postgres psql <<EOF
CREATE USER medusa WITH PASSWORD 'votre_mot_de_passe_fort';
CREATE DATABASE medusa OWNER medusa;
GRANT ALL PRIVILEGES ON DATABASE medusa TO medusa;
\q
EOF

# Tester la connexion
psql -h localhost -U medusa -d medusa
# (Entrer le mot de passe que vous avez défini)
```

---

## 5. Installer Redis

```bash
# Installer Redis
sudo apt install -y redis-server

# Configurer Redis pour écouter sur localhost
sudo nano /etc/redis/redis.conf
# Vérifier que la ligne suivante existe :
# bind 127.0.0.1

# Démarrer Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Tester Redis
redis-cli ping  # Doit retourner PONG
```

---

## 6. Configurer le Firewall de la VM

```bash
# Oracle Linux utilise firewalld, Ubuntu utilise ufw
# Pour Ubuntu :
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 9000/tcp  # Medusa API
sudo ufw allow 7001/tcp  # Medusa Admin
sudo ufw enable

# Pour Oracle Linux :
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=7001/tcp
sudo firewall-cmd --reload
```

---

## 7. Cloner et Déployer Medusa

```bash
# Créer un répertoire pour l'application
cd /home/ubuntu  # ou /home/opc si Oracle Linux
git clone https://github.com/Agalaxie/dicastri-medusa.git
cd dicastri-medusa

# Checkout la branche Oracle
git checkout oracle-cloud-deployment

# Aller dans le dossier medusa
cd medusa

# Installer les dépendances
npm install

# Créer le fichier .env
nano .env
```

### Fichier `.env` à créer :

```bash
# Database
DATABASE_URL=postgresql://medusa:votre_mot_de_passe_fort@localhost:5432/medusa

# Redis
REDIS_URL=redis://localhost:6379

# Secrets (générer des valeurs aléatoires fortes)
JWT_SECRET=votre_jwt_secret_random_64_chars
COOKIE_SECRET=votre_cookie_secret_random_64_chars

# Server
PORT=9000
NODE_ENV=production

# CORS - Remplacer par votre domaine
STORE_CORS=https://votre-domaine.com
ADMIN_CORS=https://votre-domaine.com,http://<IP_PUBLIQUE>:7001
AUTH_CORS=https://votre-domaine.com

# Admin
MEDUSA_ADMIN_ONBOARDING_TYPE=default
MEDUSA_ADMIN_BACKEND_URL=http://<IP_PUBLIQUE>:9000
```

### Générer des secrets forts :

```bash
# JWT_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# COOKIE_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## 8. Build et Migration

```bash
# Build l'application
npm run build

# Exécuter les migrations
npx medusa migrations run

# (Optionnel) Créer un utilisateur admin
npx medusa user -e admin@medusa.com -p admin_password_change_this

# (Optionnel) Seed les données de test
npm run seed
```

---

## 9. Démarrer avec PM2

```bash
# Démarrer l'application avec PM2
pm2 start npm --name "medusa-backend" -- run start

# Configurer PM2 pour démarrer au boot
pm2 startup
# Copier-coller la commande affichée et l'exécuter

pm2 save

# Voir les logs
pm2 logs medusa-backend

# Statut
pm2 status

# Redémarrer
pm2 restart medusa-backend

# Arrêter
pm2 stop medusa-backend
```

---

## 10. Tester le Déploiement

```bash
# Depuis la VM
curl http://localhost:9000/health

# Depuis votre machine locale
curl http://<IP_PUBLIQUE>:9000/health
```

Vous devriez recevoir une réponse JSON avec le statut.

### Accéder à l'admin :
```
http://<IP_PUBLIQUE>:7001
```

---

## 11. Accès Rapide avec Ngrok (Optionnel - pour tests)

Ngrok permet d'exposer votre backend via une URL publique temporaire, utile pour tester rapidement.

### Installer Ngrok

```bash
# Télécharger et installer ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok

# OU téléchargement direct
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar xvzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin

# Authentification (créer un compte gratuit sur https://ngrok.com)
ngrok config add-authtoken VOTRE_TOKEN
```

### Exposer le backend Medusa

```bash
# Exposer le port 9000 (API Medusa)
ngrok http 9000

# OU en background
nohup ngrok http 9000 > /dev/null 2>&1 &
```

Vous obtiendrez une URL du type : `https://xxxx-xx-xx-xx-xx.ngrok-free.app`

### Mettre à jour les variables d'environnement

```bash
# Éditer le .env
nano /home/ubuntu/dicastri-medusa/medusa/.env

# Mettre à jour avec l'URL ngrok :
ADMIN_CORS=https://votre-url-ngrok.ngrok-free.app
MEDUSA_ADMIN_BACKEND_URL=https://votre-url-ngrok.ngrok-free.app

# Redémarrer l'application
pm2 restart medusa-backend
```

### Accéder à l'admin via ngrok

L'admin sera accessible à : `https://votre-url-ngrok.ngrok-free.app/app`

**⚠️ Notes importantes :**
- Ngrok gratuit change l'URL à chaque redémarrage
- Limité à 1 connexion simultanée (version gratuite)
- Pour la production, utilisez un vrai nom de domaine (voir section suivante)

---

## 12. Configuration d'un Nom de Domaine (Optionnel)

### Installer Nginx comme reverse proxy

```bash
sudo apt install -y nginx

# Créer la configuration
sudo nano /etc/nginx/sites-available/medusa
```

```nginx
server {
    listen 80;
    server_name votre-domaine.com;

    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name admin.votre-domaine.com;

    location / {
        proxy_pass http://localhost:7001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Activer la configuration
sudo ln -s /etc/nginx/sites-available/medusa /etc/nginx/sites-enabled/

# Tester la config
sudo nginx -t

# Redémarrer Nginx
sudo systemctl restart nginx

# Ouvrir les ports HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Installer SSL avec Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d votre-domaine.com -d admin.votre-domaine.com
```

---

## 12. Commandes Utiles

```bash
# Voir les logs de l'application
pm2 logs medusa-backend

# Redémarrer après changement de code
cd /home/ubuntu/dicastri-medusa/medusa
git pull origin oracle-cloud-deployment
npm install
npm run build
pm2 restart medusa-backend

# Voir l'utilisation des ressources
pm2 monit

# Logs PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log

# Logs Redis
sudo tail -f /var/log/redis/redis-server.log

# Statut des services
sudo systemctl status postgresql
sudo systemctl status redis-server
sudo systemctl status nginx  # si installé
```

---

## 13. Sauvegarde et Maintenance

### Backup PostgreSQL

```bash
# Créer un backup manuel
pg_dump -h localhost -U medusa medusa > backup_$(date +%Y%m%d).sql

# Restaurer un backup
psql -h localhost -U medusa medusa < backup_20240101.sql
```

### Backup automatique avec cron

```bash
# Créer un script de backup
nano ~/backup_medusa.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
pg_dump -h localhost -U medusa medusa > $BACKUP_DIR/medusa_$DATE.sql

# Garder seulement les 7 derniers backups
find $BACKUP_DIR -name "medusa_*.sql" -mtime +7 -delete
```

```bash
chmod +x ~/backup_medusa.sh

# Ajouter au cron (tous les jours à 2h du matin)
crontab -e
# Ajouter :
0 2 * * * /home/ubuntu/backup_medusa.sh
```

---

## 14. Monitoring

```bash
# Installer htop pour monitorer les ressources
sudo apt install -y htop

# Lancer htop
htop

# Voir l'espace disque
df -h

# Voir la mémoire
free -h
```

---

## 15. Troubleshooting

### L'application ne démarre pas

```bash
# Vérifier les logs
pm2 logs medusa-backend

# Vérifier que PostgreSQL est accessible
psql -h localhost -U medusa -d medusa

# Vérifier que Redis fonctionne
redis-cli ping

# Vérifier les variables d'environnement
cat /home/ubuntu/dicastri-medusa/medusa/.env
```

### Impossible d'accéder depuis l'extérieur

1. Vérifier que les Security Rules Oracle Cloud sont configurées (ports 9000, 7001)
2. Vérifier le firewall de la VM :
   ```bash
   sudo ufw status  # Ubuntu
   sudo firewall-cmd --list-all  # Oracle Linux
   ```
3. Vérifier que l'application écoute sur 0.0.0.0 et pas seulement localhost

### Manque de mémoire (VM 1GB)

```bash
# Créer un fichier swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Rendre permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Build échoue par manque de mémoire

```bash
# Augmenter la limite de mémoire Node.js temporairement
NODE_OPTIONS="--max-old-space-size=1024" npm run build
```

---

## 16. Sécurité

### Recommandations importantes :

1. **Changer tous les mots de passe par défaut**
2. **Configurer un firewall restrictif**
3. **Désactiver l'authentification par mot de passe SSH** (clés uniquement)
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Mettre : PasswordAuthentication no
   sudo systemctl restart sshd
   ```
4. **Installer fail2ban** pour bloquer les tentatives de brute force
   ```bash
   sudo apt install -y fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```
5. **Garder le système à jour**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

---

## Notes

- Cette configuration a été testée et fonctionne sur Oracle Cloud Free Tier
- Le Free Tier offre des ressources généreuses pour un projet Medusa
- Les VM ARM (A1.Flex) offrent de meilleures performances que les VM AMD (E2.Micro)
- Pensez à monitorer votre utilisation pour rester dans les limites du Free Tier
