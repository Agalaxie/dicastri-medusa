# Déploiement Rapide sur Oracle Cloud

## 🚀 Déploiement Automatisé en 1 Commande

Une fois connecté en SSH à votre VM Oracle Cloud :

```bash
curl -fsSL https://raw.githubusercontent.com/Agalaxie/dicastri-medusa/oracle-cloud-deployment/deploy-oracle.sh | bash
```

Le script va :
- ✅ Installer Node.js, PostgreSQL, Redis, PM2
- ✅ Configurer la base de données
- ✅ Cloner le code
- ✅ Générer les secrets
- ✅ Builder l'application
- ✅ Exécuter les migrations
- ✅ Démarrer avec PM2
- ✅ Configurer le firewall

---

## 📖 Guide Complet

Pour un guide détaillé étape par étape, consultez : **[ORACLE_DEPLOYMENT.md](./ORACLE_DEPLOYMENT.md)**

Le guide complet inclut :
- Configuration de l'instance Oracle Cloud
- Installation manuelle de tous les composants
- Configuration Nginx avec nom de domaine
- Configuration SSL avec Let's Encrypt
- Ngrok pour tests rapides
- Backup et monitoring
- Troubleshooting

---

## 🆚 Différences avec la branche `main`

| Aspect | Branche `main` | Branche `oracle-cloud-deployment` |
|--------|----------------|-----------------------------------|
| **Déploiement** | Render / Railway (PaaS) | Oracle Cloud VPS (IaaS) |
| **Méthode** | Docker containers | Installation directe (PM2) |
| **Dockerfile** | ✅ Inclus | ❌ Supprimé |
| **PostgreSQL** | Service managé | Installation sur VM |
| **Redis** | Service managé | Installation sur VM |
| **Process Manager** | Docker / Platform | PM2 |
| **Coût** | Payant après free tier | Gratuit (Always Free) |

---

## 🌐 Accès

Après déploiement :

- **API Backend** : `http://<IP_PUBLIQUE>:9000`
- **Admin Panel** : `http://<IP_PUBLIQUE>:7001`
- **Health Check** : `http://<IP_PUBLIQUE>:9000/health`

---

## 📝 Prérequis

1. **Compte Oracle Cloud Free Tier**
   - Créer un compte : https://www.oracle.com/cloud/free/

2. **VM Compute Instance créée**
   - Shape recommandée : VM.Standard.A1.Flex (ARM - 4 OCPU, 24GB RAM)
   - OS : Ubuntu 22.04 ou Oracle Linux 8
   - IP publique assignée

3. **Clé SSH configurée**
   - Pour se connecter à la VM

4. **Security Rules configurées**
   - Port 22 (SSH)
   - Port 9000 (API Medusa)
   - Port 7001 (Admin Medusa)

---

## ⚡ Déploiement Manuel Rapide

Si vous préférez le faire manuellement :

```bash
# 1. Se connecter à la VM
ssh -i ~/.ssh/your_key ubuntu@<IP_PUBLIQUE>

# 2. Cloner le repo
git clone https://github.com/Agalaxie/dicastri-medusa.git
cd dicastri-medusa
git checkout oracle-cloud-deployment

# 3. Lancer le script de déploiement
bash deploy-oracle.sh
```

Le script vous guidera à travers toutes les étapes.

---

## 🔧 Commandes Utiles

```bash
# Voir les logs
pm2 logs medusa-backend

# Redémarrer l'application
pm2 restart medusa-backend

# Voir le statut
pm2 status

# Monitoring en temps réel
pm2 monit

# Mettre à jour le code
cd ~/dicastri-medusa/medusa
git pull origin oracle-cloud-deployment
npm install
npm run build
pm2 restart medusa-backend
```

---

## 🐛 Problèmes courants

### L'application ne démarre pas

```bash
pm2 logs medusa-backend
```

### Impossible d'accéder depuis l'extérieur

1. Vérifier les Security Rules Oracle Cloud
2. Vérifier le firewall de la VM : `sudo ufw status`
3. Vérifier que PM2 tourne : `pm2 status`

### Manque de mémoire (VM 1GB)

```bash
# Créer un swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📚 Ressources

- [Documentation Medusa](https://docs.medusajs.com)
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [Guide PM2](https://pm2.keymetrics.io/docs/usage/quick-start/)

---

## 💡 Support

Pour toute question ou problème, consultez :
1. Le [guide complet de déploiement](./ORACLE_DEPLOYMENT.md)
2. La section Troubleshooting du guide
3. Les issues GitHub du projet
