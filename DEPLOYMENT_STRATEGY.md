# Stratégie de déploiement - Render vs Railway

## Structure des branches

```
main                      # Branche stable de production
├── deploy/render         # Configuration Render.com
└── deploy/railway        # Configuration Railway.app
```

## Pourquoi cette stratégie ?

Cette approche permet de :
- ✅ **Tester facilement** les deux plateformes en parallèle
- ✅ **Comparer les performances** et limites de chaque plateforme
- ✅ **Basculer rapidement** entre les deux en cas de problème
- ✅ **Maintenir des configurations spécifiques** à chaque plateforme
- ✅ **Éviter les conflits** entre les configurations Render et Railway

---

## 📦 Branche `deploy/render`

### Caractéristiques
- **Plateforme** : Render.com
- **Plan** : Free tier (limité en ressources)
- **Runtime** : Docker (node:20.18.0-alpine)
- **Admin** : Désactivé par défaut (trop gourmand pour free tier)
- **URL** : https://dicastri-medusa-backend.onrender.com

### Configuration spécifique
- `medusa/.nvmrc` : 20.18.0
- `medusa/Dockerfile` : Optimisé Render
- `render.yaml` : Configuration Render
- `medusa/medusa-config.js` : Admin conditionnel

### Déploiement sur Render

1. **Connecter GitHub à Render** :
   - Sélectionner la branche `deploy/render`
   - Région : Frankfurt
   - Runtime : Docker

2. **Variables d'environnement Render** :
   ```env
   DATABASE_URL=postgresql://...
   JWT_SECRET=supersecret
   COOKIE_SECRET=supersecret
   STORE_CORS=http://localhost:8000,https://docs.medusajs.com
   ADMIN_CORS=http://localhost:9000,https://docs.medusajs.com
   AUTH_CORS=http://localhost:8000,http://localhost:9000,https://docs.medusajs.com
   STRIPE_API_KEY=sk_test_...
   ```

3. **Pour activer l'admin** (plan payant uniquement) :
   ```env
   MEDUSA_ADMIN_DISABLE=false
   ```

---

## 🚂 Branche `deploy/railway`

### Caractéristiques
- **Plateforme** : Railway.app
- **Plan** : Free tier (500h/mois, plus généreux en ressources que Render)
- **Runtime** : Auto-détecté (Node.js)
- **Admin** : Peut être activé (Railway free tier a plus de RAM)
- **URL** : À configurer lors du déploiement

### Avantages Railway vs Render
- ✅ Plus de ressources sur le free tier
- ✅ Build plus rapides
- ✅ Possibilité d'activer l'admin panel
- ✅ Meilleure expérience développeur (logs, metrics)
- ⚠️ Limite mensuelle de 500h (vs illimité sur Render)

### Configuration spécifique Railway

Créer `railway.toml` ou utiliser l'interface web :
```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "npm run start"
healthcheckPath = "/health"
restartPolicyType = "ON_FAILURE"
```

### Variables d'environnement Railway
Mêmes variables que Render, mais vous pouvez ajouter :
```env
MEDUSA_ADMIN_DISABLE=false  # Admin peut être activé sur Railway
PORT=9000
NODE_ENV=production
```

---

## 🔄 Comment switcher entre les branches

### Pour tester Render

```bash
# Switcher vers la branche Render
git checkout deploy/render

# Faire des modifications spécifiques à Render
# (ex: ajuster le Dockerfile, render.yaml)

# Committer et pusher
git add .
git commit -m "feat: Update Render configuration"
git push origin deploy/render
```

**Render redéploiera automatiquement** à chaque push sur `deploy/render`.

---

### Pour tester Railway

```bash
# Switcher vers la branche Railway
git checkout deploy/railway

# Faire des modifications spécifiques à Railway
# (ex: railway.toml, activer l'admin)

# Committer et pusher
git add .
git commit -m "feat: Enable admin panel on Railway"
git push origin deploy/railway
```

**Railway redéploiera automatiquement** à chaque push sur `deploy/railway`.

---

## 🔀 Synchroniser les branches

Si vous faites des changements communs (code métier, nouvelles features) :

### 1. Faire le changement sur `main`

```bash
git checkout main

# Faire vos modifications de code
# (ex: nouveau module, API route, etc.)

git add .
git commit -m "feat: Add new product feature"
git push origin main
```

### 2. Merger main dans les branches de déploiement

```bash
# Mettre à jour deploy/render
git checkout deploy/render
git merge main
git push origin deploy/render

# Mettre à jour deploy/railway
git checkout deploy/railway
git merge main
git push origin deploy/railway

# Retourner sur main
git checkout main
```

---

## 📊 Comparaison Render vs Railway

| Critère | Render (Free) | Railway (Free) |
|---------|---------------|----------------|
| **RAM** | 512 MB | 512 MB - 1 GB |
| **CPU** | Partagé (limité) | Partagé (meilleur) |
| **Temps de build** | Plus lent | Plus rapide |
| **Limite temps** | Illimité | 500h/mois |
| **Cold start** | 30-60s | 10-20s |
| **Admin Medusa** | ❌ Trop lourd | ✅ Possible |
| **Auto-deploy** | ✅ Oui | ✅ Oui |
| **Logs** | Basiques | Excellents |
| **Metrics** | Limitées | Détaillées |
| **DX** | Moyen | Excellent |

---

## 🎯 Recommandations

### Utiliser Render si :
- ✅ Vous voulez un déploiement illimité en temps
- ✅ Vous n'avez pas besoin de l'admin panel en production
- ✅ Vous acceptez des cold starts plus longs
- ✅ Budget $0 strict

### Utiliser Railway si :
- ✅ Vous voulez activer l'admin panel
- ✅ Vous avez besoin de builds rapides
- ✅ Vous voulez de meilleurs logs et metrics
- ✅ 500h/mois suffisent (≈ 16h/jour)
- ✅ Meilleure expérience développeur

### Solution hybride (recommandée)
- **Production** : Railway (meilleure performance, admin activé)
- **Staging/Test** : Render (gratuit illimité, pas besoin d'admin)

---

## 📝 Checklist de déploiement

### Avant de déployer sur une nouvelle plateforme

- [ ] Créer/switcher vers la branche appropriée (`deploy/render` ou `deploy/railway`)
- [ ] Vérifier les fichiers de configuration (Dockerfile, render.yaml, railway.toml)
- [ ] Configurer les variables d'environnement sur la plateforme
- [ ] Vérifier DATABASE_URL (Supabase Session Pooler)
- [ ] Configurer CORS avec les bonnes URLs
- [ ] Tester localement avant de déployer
- [ ] Vérifier que les secrets (Stripe, JWT) sont bien configurés
- [ ] Pusher sur la branche de déploiement
- [ ] Monitorer les logs de déploiement
- [ ] Tester l'endpoint `/health`
- [ ] Tester les routes API principales

---

## 🚨 Résolution de problèmes

### Erreur "MedusaRequest export not found"
➡️ Vérifier Node.js version (doit être 20.x)
- Render : Vérifier `.nvmrc` et Dockerfile
- Railway : Vérifier les paramètres de build

### Admin panel ne démarre pas
➡️ Vérifier les ressources disponibles
- Render free tier : Désactiver l'admin (`MEDUSA_ADMIN_DISABLE=true`)
- Railway free tier : Peut être activé (`MEDUSA_ADMIN_DISABLE=false`)

### Build échoue
➡️ Vérifier les logs
- Routes API doivent être en `.js` (pas `.ts`)
- `package-lock.json` doit être compatible avec Node 20
- Toutes les dépendances doivent être dans `dependencies` (pas `devDependencies`)

### CORS errors
➡️ Vérifier les variables d'environnement
```env
STORE_CORS=https://votre-frontend.com
ADMIN_CORS=https://votre-admin.com
AUTH_CORS=https://votre-frontend.com,https://votre-admin.com
```

---

## 📚 Ressources

- [Documentation Render](https://docs.render.com/)
- [Documentation Railway](https://docs.railway.app/)
- [Documentation Medusa v2](https://docs.medusajs.com/)
- [Troubleshooting complet](./INSTALLATION_LOG.md#-déploiement-render---problèmes-et-solutions)

---

**Dernière mise à jour** : 2025-11-13
**Status actuel** :
- ✅ Render : Déployé et fonctionnel (sans admin)
- 🔄 Railway : Branche créée, prêt à déployer
