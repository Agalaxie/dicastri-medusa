# Déploiement Railway - Guide rapide

## 🚂 Avantages de Railway pour Medusa

Railway offre plusieurs avantages par rapport à Render pour le free tier :
- ✅ **Admin panel activable** (plus de ressources disponibles)
- ✅ **Builds plus rapides** (~2-5 min vs 5-10 min)
- ✅ **Cold starts plus courts** (10-20s vs 30-60s)
- ✅ **Meilleurs logs et metrics**
- ✅ **Meilleure expérience développeur**

Limite : 500 heures/mois (suffisant pour développement)

---

## 📋 Prérequis

- ✅ Compte GitHub
- ✅ Code sur la branche `deploy/railway`
- ✅ Base de données Supabase configurée
- ✅ Clés Stripe (optionnel)

---

## 🚀 Étapes de déploiement

### 1. Créer un compte Railway

1. Allez sur https://railway.app
2. Cliquez sur **"Start a New Project"**
3. Connectez-vous avec GitHub

### 2. Créer un nouveau projet

1. Cliquez sur **"Deploy from GitHub repo"**
2. Sélectionnez le repo **`dicastri-medusa`**
3. **IMPORTANT** : Sélectionnez la branche **`deploy/railway`**
4. Railway va détecter automatiquement le projet Node.js

### 3. Configurer le projet

Railway va détecter qu'il y a plusieurs services (medusa + storefront).

**Configurez uniquement le backend pour l'instant :**
- Root Directory : `medusa`
- Build Command : Détecté automatiquement (`npm install && npm run build`)
- Start Command : `npm run start`

### 4. Configurer les variables d'environnement

Allez dans **Settings** → **Variables** et ajoutez :

```env
# Base de données Supabase
DATABASE_URL=postgresql://postgres.glnobjetjwzgkwqbjduy:123Rondoudou123@aws-1-eu-north-1.pooler.supabase.com:5432/postgres

# Secrets JWT
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret

# CORS - À mettre à jour après avoir l'URL Railway
STORE_CORS=http://localhost:8000,https://docs.medusajs.com
ADMIN_CORS=http://localhost:9000,https://docs.medusajs.com
AUTH_CORS=http://localhost:8000,http://localhost:9000,https://docs.medusajs.com

# Stripe (optionnel)
STRIPE_API_KEY=sk_test_************************************

# Admin Panel - ACTIVÉ sur Railway!
MEDUSA_ADMIN_DISABLE=false

# Node version
NODE_ENV=production
```

### 5. Configurer le domaine public

1. Allez dans **Settings** → **Networking**
2. Cliquez sur **"Generate Domain"**
3. Railway vous donnera une URL type : `https://medusa-production-xxxx.up.railway.app`
4. **Copiez cette URL**

### 6. Mettre à jour les CORS

Retournez dans **Variables** et mettez à jour :

```env
# Remplacez par votre URL Railway
STORE_CORS=https://medusa-production-xxxx.up.railway.app,http://localhost:8000,https://docs.medusajs.com
ADMIN_CORS=https://medusa-production-xxxx.up.railway.app,http://localhost:9000,https://docs.medusajs.com
AUTH_CORS=https://medusa-production-xxxx.up.railway.app,http://localhost:8000,http://localhost:9000,https://docs.medusajs.com
```

### 7. Déployer

1. Railway va automatiquement déployer après la configuration
2. Suivez les logs dans l'onglet **"Deployments"**
3. Le premier build prend ~5 minutes

### 8. Vérifier le déploiement

Une fois déployé, testez :

**Health check :**
```bash
curl https://medusa-production-xxxx.up.railway.app/health
```

**Admin panel :**
Ouvrez : `https://medusa-production-xxxx.up.railway.app/app`

Connectez-vous avec :
- Email : `stephdumaz@gmail.com`
- Password : `Rondoudou66!`

**API Store :**
```bash
curl https://medusa-production-xxxx.up.railway.app/store/regions
```

---

## 🔧 Configuration avancée

### Activer les logs persistants

1. Allez dans **Settings** → **Observability**
2. Activez **"Persistent Logs"**

### Configurer les alertes

1. **Settings** → **Alerts**
2. Configurez les notifications email/Slack

### Optimiser les performances

Railway détecte automatiquement Node.js et optimise :
- ✅ Cache des dépendances npm
- ✅ Build layers Docker optimisés
- ✅ Auto-scaling (plans payants)

---

## 📊 Monitoring

### Logs en temps réel

```bash
# Via Railway CLI (optionnel)
railway logs
```

Ou via l'interface web : **Deployments** → **View Logs**

### Metrics disponibles

Railway fournit automatiquement :
- 📈 CPU usage
- 📈 Memory usage
- 📈 Network I/O
- 📈 Request count
- 📈 Response times

---

## 🔄 Déploiements automatiques

Railway redéploie automatiquement à chaque push sur `deploy/railway` :

```bash
# Faire des modifications
git checkout deploy/railway
# ... modifications ...
git add .
git commit -m "feat: Update configuration"
git push origin deploy/railway

# Railway redéploie automatiquement (2-5 min)
```

---

## 💰 Limites du Free Tier

- **500 heures/mois** (~16h/jour)
- **1 GB RAM** par service
- **1 GB de stockage**
- **100 GB de bande passante/mois**

**Pour le plan payant** :
- $5/mois par service
- Ressources illimitées
- Support prioritaire
- Scaling automatique

---

## 🐛 Troubleshooting

### Build échoue

**Vérifier :**
- Root Directory est bien `medusa`
- Node version 20.x est utilisée (.nvmrc)
- Toutes les variables d'env sont configurées

**Logs à vérifier :**
```
Settings → Deployments → View Logs
```

### Admin panel ne charge pas

**Solutions :**
1. Vérifier que `MEDUSA_ADMIN_DISABLE=false`
2. Vérifier les CORS dans les variables d'env
3. Attendre 2-3 min après le déploiement (compilation admin)

### CORS errors

**Vérifier dans Variables :**
```env
STORE_CORS=https://votre-url-railway.up.railway.app,...
ADMIN_CORS=https://votre-url-railway.up.railway.app,...
AUTH_CORS=https://votre-url-railway.up.railway.app,...
```

### Out of memory

Railway free tier a plus de RAM que Render, mais si vous avez des problèmes :
1. Vérifier les logs de memory usage
2. Optimiser les requêtes DB
3. Envisager le plan payant ($5/mois)

---

## 🔐 Sécurité

### Secrets recommandés à changer

Avant la production, changez :

```env
JWT_SECRET=<générer un secret fort>
COOKIE_SECRET=<générer un secret fort>
```

Générer des secrets forts :
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Variables sensibles

Railway masque automatiquement les variables marquées comme sensibles.

---

## 🌐 Connecter le Frontend

Une fois le backend Railway déployé, mettez à jour le frontend :

**Dans `storefront/.env.local` ou Vercel :**
```env
MEDUSA_BACKEND_URL=https://medusa-production-xxxx.up.railway.app
```

---

## 📚 Ressources

- [Documentation Railway](https://docs.railway.app/)
- [Railway CLI](https://docs.railway.app/develop/cli)
- [Medusa v2 Docs](https://docs.medusajs.com/)
- [Troubleshooting Render vs Railway](./DEPLOYMENT_STRATEGY.md)

---

## ✅ Checklist finale

Avant de marquer le déploiement comme terminé :

- [ ] Backend Railway accessible
- [ ] Health check retourne 200
- [ ] Admin panel accessible et fonctionnel
- [ ] Login admin fonctionne
- [ ] API Store retourne les régions
- [ ] CORS configurés correctement
- [ ] Logs Railway sont propres (pas d'erreurs)
- [ ] Variables d'environnement toutes configurées
- [ ] Domaine public généré
- [ ] Frontend connecté au backend Railway

---

**Déployé le** : En attente
**URL Backend** : À compléter après déploiement
**Status Admin** : ✅ Activé sur Railway
