# Guide de déploiement Medusa v2 sur Oracle Cloud (VPS gratuit)

## Prérequis
- Compte Oracle Cloud créé
- VPS Ubuntu créé (VM.Standard.E2.1.Micro - Always Free)
- Accès SSH au VPS

## Étape 1 : Créer le VPS sur Oracle Cloud

1. Connecte-toi à https://cloud.oracle.com
2. Va dans **Compute** → **Instances**
3. Clique sur **Create Instance**
4. Configure :
   - **Name** : medusa-server
   - **Image** : Ubuntu 22.04 (ou 24.04)
   - **Shape** : VM.Standard.E2.1.Micro (Always Free)
   - **Add SSH keys** : Génère ou upload ta clé SSH
5. Clique sur **Create**
6. Note l'**adresse IP publique**

## Étape 2 : Configurer le Firewall Oracle Cloud

1. Va dans ton instance → **Subnet** → **Default Security List**
2. Ajoute les règles **Ingress Rules** :
   - Port 22 (SSH) - déjà configuré
   - Port 80 (HTTP) - Source: 0.0.0.0/0
   - Port 443 (HTTPS) - Source: 0.0.0.0/0
   - Port 9000 (Medusa) - Source: 0.0.0.0/0

## Étape 3 : Se connecter au VPS

```bash
# Remplace <IP> par l'adresse IP de ton VPS
ssh ubuntu@<IP>
```

## Étape 4 : Installer Docker et Docker Compose

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo apt install docker-compose -y

# Redémarrer la session pour appliquer les changements
exit
```

Reconnecte-toi : `ssh ubuntu@<IP>`

## Étape 5 : Configurer le firewall Ubuntu (iptables)

```bash
# Autoriser les ports nécessaires
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9000 -j ACCEPT

# Sauvegarder les règles
sudo netfilter-persistent save
```

Si `netfilter-persistent` n'est pas installé :
```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

## Étape 6 : Transférer les fichiers

Depuis ton PC local :

```bash
# Créer une archive du projet
cd C:\Users\audif\Desktop
tar -czf dicastri-medusa.tar.gz dicastri-medusa/

# Transférer sur le VPS (remplace <IP>)
scp dicastri-medusa.tar.gz ubuntu@<IP>:~
```

## Étape 7 : Déployer sur le VPS

Sur le VPS :

```bash
# Extraire l'archive
tar -xzf dicastri-medusa.tar.gz
cd dicastri-medusa

# Copier et configurer les variables d'environnement
cp .env.production .env

# IMPORTANT : Éditer .env pour changer les secrets
nano .env
# Génère des secrets avec: openssl rand -base64 32
# Change JWT_SECRET, COOKIE_SECRET et les mots de passe

# Lancer les conteneurs
docker-compose up -d

# Voir les logs
docker-compose logs -f medusa
```

## Étape 8 : Vérifier le déploiement

```bash
# Vérifier que les conteneurs tournent
docker-compose ps

# Tester l'API
curl http://localhost:9000/health
```

Accède depuis ton navigateur :
- API : `http://<IP>:9000`
- Admin : `http://<IP>:9000/app`

## Étape 9 : Créer un utilisateur admin

```bash
docker-compose exec medusa npx medusa user -e admin@example.com -p supersecret
```

## Commandes utiles

```bash
# Arrêter les conteneurs
docker-compose down

# Redémarrer
docker-compose restart

# Voir les logs
docker-compose logs -f

# Mettre à jour après un changement
git pull  # si tu utilises git
docker-compose up -d --build

# Backup de la base de données
docker-compose exec postgres pg_dump -U medusa medusa > backup.sql

# Restaurer la base de données
cat backup.sql | docker-compose exec -T postgres psql -U medusa medusa
```

## Problèmes connus

### Si l'erreur MedusaRequest persiste :

C'est un bug connu de Medusa v2. Solutions possibles :
1. Attendre une mise à jour de Medusa
2. Utiliser Medusa Cloud (payant)
3. Rester en développement local

### Si le port 9000 n'est pas accessible :

Vérifie :
1. Le firewall Oracle Cloud (Security List)
2. Le firewall Ubuntu (iptables)
3. Que les conteneurs tournent : `docker-compose ps`

### Logs utiles :

```bash
# Logs Medusa
docker-compose logs -f medusa

# Logs Postgres
docker-compose logs -f postgres

# Logs Redis
docker-compose logs -f redis
```

## Amélioration future : Ajouter un nom de domaine

1. Achète un nom de domaine (ex: Namecheap, OVH)
2. Configure les DNS pour pointer vers l'IP de ton VPS
3. Installe un reverse proxy (Nginx) avec Let's Encrypt pour HTTPS

Besoin d'aide ? Ouvre une issue sur le repo GitHub !
