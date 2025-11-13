#!/bin/bash

###############################################################################
# Script de déploiement automatisé pour Oracle Cloud Free Tier
# Usage: bash deploy-oracle.sh
###############################################################################

set -e  # Arrêter en cas d'erreur

echo "==================================="
echo "  Déploiement Medusa sur Oracle"
echo "==================================="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
APP_DIR="$HOME/dicastri-medusa"
MEDUSA_DIR="$APP_DIR/medusa"

# Fonction pour afficher les messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

###############################################################################
# 1. Vérifier les prérequis
###############################################################################

print_info "Vérification des prérequis..."

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé"
    print_info "Installation de Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    print_success "Node.js installé"
else
    NODE_VERSION=$(node --version)
    print_success "Node.js détecté: $NODE_VERSION"
fi

# Vérifier PostgreSQL
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL n'est pas installé"
    print_info "Installation de PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    print_success "PostgreSQL installé"
else
    print_success "PostgreSQL détecté"
fi

# Vérifier Redis
if ! command -v redis-cli &> /dev/null; then
    print_error "Redis n'est pas installé"
    print_info "Installation de Redis..."
    sudo apt install -y redis-server
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
    print_success "Redis installé"
else
    print_success "Redis détecté"
fi

# Vérifier PM2
if ! command -v pm2 &> /dev/null; then
    print_info "Installation de PM2..."
    sudo npm install -g pm2
    print_success "PM2 installé"
else
    print_success "PM2 détecté"
fi

# Vérifier Git
if ! command -v git &> /dev/null; then
    print_info "Installation de Git..."
    sudo apt install -y git
    print_success "Git installé"
else
    print_success "Git détecté"
fi

echo ""

###############################################################################
# 2. Configuration de la base de données
###############################################################################

print_info "Configuration de PostgreSQL..."

# Demander le mot de passe PostgreSQL
read -sp "Entrez le mot de passe pour l'utilisateur PostgreSQL 'medusa': " DB_PASSWORD
echo ""

# Créer l'utilisateur et la base de données
sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='medusa'" | grep -q 1 || \
sudo -u postgres psql <<EOF
CREATE USER medusa WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE medusa OWNER medusa;
GRANT ALL PRIVILEGES ON DATABASE medusa TO medusa;
EOF

print_success "Base de données PostgreSQL configurée"
echo ""

###############################################################################
# 3. Cloner ou mettre à jour le repository
###############################################################################

if [ -d "$APP_DIR" ]; then
    print_info "Mise à jour du code existant..."
    cd "$APP_DIR"
    git fetch origin
    git checkout oracle-cloud-deployment
    git pull origin oracle-cloud-deployment
    print_success "Code mis à jour"
else
    print_info "Clonage du repository..."
    git clone https://github.com/Agalaxie/dicastri-medusa.git "$APP_DIR"
    cd "$APP_DIR"
    git checkout oracle-cloud-deployment
    print_success "Repository cloné"
fi

cd "$MEDUSA_DIR"
echo ""

###############################################################################
# 4. Configuration des variables d'environnement
###############################################################################

print_info "Configuration des variables d'environnement..."

# Générer des secrets
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
COOKIE_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

# Demander l'IP publique
echo "Quelle est l'IP publique de votre instance Oracle Cloud?"
read -p "IP publique: " PUBLIC_IP

# Créer le fichier .env
cat > .env <<EOF
# Database
DATABASE_URL=postgresql://medusa:$DB_PASSWORD@localhost:5432/medusa

# Redis
REDIS_URL=redis://localhost:6379

# Secrets
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET

# Server
PORT=9000
NODE_ENV=production

# CORS
STORE_CORS=http://$PUBLIC_IP:9000,http://localhost:9000
ADMIN_CORS=http://$PUBLIC_IP:7001,http://localhost:7001
AUTH_CORS=http://$PUBLIC_IP:9000,http://localhost:9000

# Admin
MEDUSA_ADMIN_ONBOARDING_TYPE=default
MEDUSA_ADMIN_BACKEND_URL=http://$PUBLIC_IP:9000
EOF

print_success "Variables d'environnement configurées"
echo ""

###############################################################################
# 5. Installation des dépendances
###############################################################################

print_info "Installation des dépendances NPM..."
npm install
print_success "Dépendances installées"
echo ""

###############################################################################
# 6. Build de l'application
###############################################################################

print_info "Build de l'application..."

# Augmenter la limite de mémoire pour le build si RAM limitée
if [ "$(free -m | awk '/^Mem:/{print $2}')" -lt 2000 ]; then
    print_info "RAM limitée détectée, ajustement de la limite de mémoire Node.js..."
    NODE_OPTIONS="--max-old-space-size=1024" npm run build
else
    npm run build
fi

print_success "Application buildée"
echo ""

###############################################################################
# 7. Migrations de base de données
###############################################################################

print_info "Exécution des migrations..."
npx medusa migrations run
print_success "Migrations exécutées"
echo ""

###############################################################################
# 8. Création de l'utilisateur admin (optionnel)
###############################################################################

read -p "Voulez-vous créer un utilisateur admin? (o/n): " CREATE_ADMIN

if [ "$CREATE_ADMIN" = "o" ] || [ "$CREATE_ADMIN" = "O" ]; then
    read -p "Email admin: " ADMIN_EMAIL
    read -sp "Mot de passe admin: " ADMIN_PASSWORD
    echo ""

    npx medusa user -e "$ADMIN_EMAIL" -p "$ADMIN_PASSWORD"
    print_success "Utilisateur admin créé"
fi

echo ""

###############################################################################
# 9. Seed des données (optionnel)
###############################################################################

read -p "Voulez-vous importer les données de démo? (o/n): " SEED_DATA

if [ "$SEED_DATA" = "o" ] || [ "$SEED_DATA" = "O" ]; then
    print_info "Import des données de démo..."
    npm run seed
    print_success "Données importées"
fi

echo ""

###############################################################################
# 10. Configuration du firewall
###############################################################################

print_info "Configuration du firewall..."

if command -v ufw &> /dev/null; then
    # Ubuntu
    sudo ufw allow 22/tcp
    sudo ufw allow 9000/tcp
    sudo ufw allow 7001/tcp
    echo "y" | sudo ufw enable || true
    print_success "Firewall UFW configuré"
elif command -v firewall-cmd &> /dev/null; then
    # Oracle Linux
    sudo firewall-cmd --permanent --add-port=22/tcp
    sudo firewall-cmd --permanent --add-port=9000/tcp
    sudo firewall-cmd --permanent --add-port=7001/tcp
    sudo firewall-cmd --reload
    print_success "Firewall firewalld configuré"
fi

echo ""

###############################################################################
# 11. Démarrage avec PM2
###############################################################################

print_info "Démarrage de l'application avec PM2..."

# Arrêter l'instance existante si elle existe
pm2 stop medusa-backend 2>/dev/null || true
pm2 delete medusa-backend 2>/dev/null || true

# Démarrer l'application
pm2 start npm --name "medusa-backend" -- run start

# Configurer PM2 pour démarrer au boot
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME
pm2 save

print_success "Application démarrée avec PM2"
echo ""

###############################################################################
# 12. Vérification de santé
###############################################################################

print_info "Vérification de l'application..."
sleep 5

if curl -f http://localhost:9000/health &>/dev/null; then
    print_success "Application accessible sur http://localhost:9000"
else
    print_error "L'application ne répond pas sur http://localhost:9000"
    print_info "Vérifiez les logs avec: pm2 logs medusa-backend"
fi

echo ""

###############################################################################
# Résumé
###############################################################################

echo "==================================="
echo "  Déploiement terminé!"
echo "==================================="
echo ""
print_success "Backend Medusa: http://$PUBLIC_IP:9000"
print_success "Admin Medusa: http://$PUBLIC_IP:7001"
echo ""
echo "Commandes utiles:"
echo "  - Voir les logs: pm2 logs medusa-backend"
echo "  - Redémarrer: pm2 restart medusa-backend"
echo "  - Statut: pm2 status"
echo "  - Monitoring: pm2 monit"
echo ""
print_info "N'oubliez pas de configurer les Security Rules dans Oracle Cloud"
print_info "pour autoriser les ports 9000 et 7001!"
echo ""
