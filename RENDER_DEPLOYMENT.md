# Guide de déploiement Render pour Medusa

Ce guide vous aide à déployer votre application Medusa sur Render.

## Prérequis

1. Un compte Render (gratuit : https://render.com)
2. Une base de données PostgreSQL (voir options ci-dessous)
3. Ce repository Git connecté à Render

## Services créés

Le fichier `render.yaml` configure automatiquement :

- **dicastri-medusa-redis** : Service Redis gratuit pour le cache
- **dicastri-medusa-backend** : Application Medusa (Docker)

## Configuration requise

### 1. Base de données PostgreSQL

Vous devez créer une base de données PostgreSQL. Options :

#### Option A : PostgreSQL sur Render (Payant - $7/mois minimum)
```bash
# Dans le dashboard Render :
# 1. Créez un nouveau PostgreSQL
# 2. Copiez l'URL de connexion "External Database URL"
```

#### Option B : Supabase (Plan gratuit disponible)
```bash
# 1. Créez un projet sur https://supabase.com
# 2. Allez dans Settings > Database
# 3. Copiez la "Connection string" (mode "Session")
# Format : postgresql://postgres.PROJECT_ID:PASSWORD@aws-region.pooler.supabase.com:5432/postgres
```

#### Option C : Neon (Plan gratuit disponible)
```bash
# 1. Créez un projet sur https://neon.tech
# 2. Copiez la connection string
```

### 2. Variables d'environnement à configurer manuellement

Dans le dashboard Render, configurez ces variables pour le service `dicastri-medusa-backend` :

#### Obligatoires :

1. **DATABASE_URL**
   ```
   postgresql://user:password@host:5432/database
   ```
   Utilisez l'URL de votre base de données PostgreSQL

2. **STORE_CORS**
   ```
   https://votre-frontend.com,https://www.votre-frontend.com
   ```
   URLs autorisées pour votre storefront

3. **ADMIN_CORS**
   ```
   https://dicastri-medusa-backend.onrender.com
   ```
   URL de votre backend Render (ajustez après déploiement)

4. **AUTH_CORS**
   ```
   https://dicastri-medusa-backend.onrender.com,https://votre-frontend.com
   ```
   URLs autorisées pour l'authentification

#### Optionnelles (pour Stripe) :

5. **STRIPE_API_KEY**
   ```
   sk_test_... ou sk_live_...
   ```

6. **STRIPE_WEBHOOK_SECRET**
   ```
   whsec_...
   ```

### 3. Variables générées automatiquement

Ces variables sont générées automatiquement par Render :
- JWT_SECRET
- COOKIE_SECRET
- REDIS_URL (connecté au service Redis)
- NODE_ENV (défini à "production")
- PORT (défini à 9000)

## Étapes de déploiement

### 1. Connecter votre repository

```bash
# Si vous déployez depuis GitHub :
1. Allez sur https://dashboard.render.com
2. Cliquez sur "New" > "Blueprint"
3. Connectez votre repository GitHub
4. Render détectera automatiquement render.yaml
```

### 2. Configurer les variables d'environnement

```bash
1. Une fois les services créés, allez dans "dicastri-medusa-backend"
2. Allez dans "Environment"
3. Ajoutez les variables obligatoires listées ci-dessus
```

### 3. Déployer

```bash
# Le déploiement démarre automatiquement
# Surveillez les logs dans le dashboard Render
```

## Vérification post-déploiement

### 1. Vérifier que l'API répond

```bash
curl https://dicastri-medusa-backend.onrender.com/health
# Devrait retourner : {"status":"ok"}
```

### 2. Vérifier la connexion Redis

```bash
# Dans les logs Render, vous devriez voir :
# "Redis connection established"
```

### 3. Vérifier la base de données

```bash
# Les migrations devraient s'exécuter automatiquement au démarrage
# Vérifiez les logs pour :
# "Database migrations completed"
```

## Seed de données (optionnel)

Pour charger des données de test :

```bash
# Via le Shell Render :
1. Allez dans votre service > Shell
2. Exécutez :
   yarn seed
```

## Problèmes courants

### Erreur : "Cannot connect to database"

- Vérifiez que DATABASE_URL est correctement configurée
- Testez la connexion depuis un autre outil (psql, pgAdmin)
- Vérifiez que votre fournisseur de base de données autorise les connexions depuis Render

### Erreur : "Redis connection failed"

- Le service Redis doit être créé AVANT le backend
- Vérifiez que les deux services sont dans la même région

### Build Docker échoue

- Vérifiez les logs de build dans Render
- Le Dockerfile utilise maintenant Yarn (pas npm)
- Assurez-vous que yarn.lock est commité

### L'application redémarre en boucle

- Vérifiez toutes les variables d'environnement obligatoires
- Consultez les logs d'application dans Render
- Vérifiez que le PORT 9000 est correct

## Plan gratuit Render - Limitations

- **Web Service** : 750 heures/mois (suffisant pour 1 service)
- **Redis** : 25 MB de mémoire
- **Pas de PostgreSQL gratuit** : Utilisez Supabase ou Neon

## Prochaines étapes

1. Configurez votre frontend pour pointer vers l'URL Render
2. Configurez un nom de domaine personnalisé (optionnel)
3. Activez les webhooks Stripe si nécessaire
4. Configurez les sauvegardes de base de données

## Support

- Documentation Render : https://render.com/docs
- Documentation Medusa : https://docs.medusajs.com
- Logs : Consultez le dashboard Render > votre service > Logs
