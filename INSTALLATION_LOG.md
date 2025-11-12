# Journal d'installation Medusa B2C Starter

## Configuration cible
- **Backend** : Medusa v2 en local
- **Frontend** : Next.js Starter (storefront)
- **Base de données** : Supabase (PostgreSQL)
- **Paiement** : Stripe (clés test configurées)
- **Déploiement futur** : Vercel (frontend) + Railway/Supabase (backend/BDD)

---

## Problèmes rencontrés et solutions

### 1. Installation interactive qui bloque
**Problème** : La commande `npx create-medusa-app@latest` pose des questions interactives et bloque sur la configuration PostgreSQL.

**Solution** : Utiliser l'option `--skip-db` pour éviter l'assistant interactif
```bash
npx create-medusa-app@latest medusa --skip-db
```

---

### 2. Erreur d'authentification Supabase
**Problème** : Erreur "authentication par mot de passe échouée" lors de la tentative de connexion à Supabase.

**Causes multiples** :
- Username incorrect : utilisait `postgres.glnobjetjwzgkwqbjduy` au lieu de `postgres`
- Mot de passe avec caractères spéciaux (`*`, `^`) non supportés en copier-coller dans PowerShell
- Mauvais type de connexion (Direct vs Session Pooler)

**Solution** :
1. Changé le mot de passe Supabase pour `123Rondoudou123` (sans caractères spéciaux complexes)
2. Utilisé la **Session Pooler connection** au lieu de Direct Connection
3. URL finale dans `.env` :
```
DATABASE_URL=postgresql://postgres.glnobjetjwzgkwqbjduy:123Rondoudou123@aws-1-eu-north-1.pooler.supabase.com:5432/postgres
```

**Pourquoi Session Pooler ?** : Medusa maintient des connexions persistantes, le Session Pooler est conçu pour gérer ce type de connexions.

---

### 3. Script de migration inexistant
**Problème** : `npm run db:migrate` retourne "Missing script: db:migrate"

**Cause** : Medusa v2 utilise une structure différente de v1

**Solution** : Utiliser la CLI Medusa directement
```bash
npx medusa db:migrate
```

---

### 4. Tables manquantes dans la base de données
**Problème** : Au lancement de `npm run dev`, erreurs multiples "relation does not exist" :
- `relation "currency" does not exist`
- `relation "tax_provider" does not exist`
- `relation "payment_provider" does not exist`
- etc.

**Cause** : Les migrations n'ont pas été exécutées automatiquement au démarrage

**Solution** : Exécuter manuellement les migrations avant le premier démarrage
```bash
npx medusa db:migrate
```

---

### 5. Confusion entre dossiers backend et medusa
**Problème** : Présence de deux dossiers `backend/` et `medusa/` dans le projet

**Cause** : Tentatives multiples de création du backend

**Solution** :
- Le dossier **actif** est `medusa/` (contient le backend fonctionnel)
- Le dossier `backend/` peut être ignoré ou supprimé
- Structure finale :
  ```
  dicastri-medusa/
  ├── medusa/          ← BACKEND (port 9000)
  ├── storefront/      ← FRONTEND (port 8000)
  └── backend/         ← (ancien, ignoré)
  ```

---

### 6. Création du compte admin
**Problème** : Interface de connexion sur http://localhost:9000 sans possibilité de créer un compte

**Cause** : Medusa n'a pas d'interface "Sign Up" par défaut, il faut créer l'admin via CLI

**Solution** :
```bash
cd medusa
npx medusa user -e stephdumaz@gmail.com -p Rondoudou66!
```

**Identifiants admin créés** :
- Email : `stephdumaz@gmail.com`
- Password : `Rondoudou66!`

---

### 7. Erreur "A valid publishable key is required"
**Problème** : Le frontend refuse de démarrer avec l'erreur :
```
A valid publishable key is required to proceed with the request
```

**Cause** : Le fichier `.env.local` du frontend contenait `pk_test` (valeur par défaut) au lieu d'une vraie clé

**Solution** :
1. Se connecter à l'admin Medusa : http://localhost:9000
2. Aller dans **Settings** → **Publishable API Keys**
3. Créer ou copier une clé existante
4. Mettre à jour le fichier `storefront/.env.local` :
```env
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_58dfaf8e246df51894b0c7291e70961ec094bb2ac7727493c072c1c71eaaec9f
```
5. **Redémarrer le frontend** (important !)

---

### 8. Erreur "No regions found"
**Problème** : Le frontend affiche "No regions found. Please set up regions in your Medusa Admin."

**Cause** : Le script de seed initial (`npm run seed`) a échoué partiellement, créant des données incomplètes

**Solution tentée** :
```bash
cd medusa
npm run seed
```
**Erreur obtenue** : `Tax region with country_code: fr, already exists.`

**Solution finale** : Création d'un script personnalisé `fix-regions.ts` pour vérifier les régions existantes :
```bash
cd medusa
npx medusa exec ./src/scripts/fix-regions.ts
```

**Résultat** : 2 régions Europe existaient déjà en EUR. Après redémarrage du frontend, tout a fonctionné.

---

## Configuration finale fonctionnelle

### Fichier `.env` du backend (`medusa/.env`)
```env
MEDUSA_ADMIN_ONBOARDING_TYPE=default
STORE_CORS=http://localhost:8000,https://docs.medusajs.com
ADMIN_CORS=http://localhost:5173,http://localhost:9000,https://docs.medusajs.com
AUTH_CORS=http://localhost:5173,http://localhost:9000,http://localhost:8000,https://docs.medusajs.com
REDIS_URL=redis://localhost:6379
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret
DATABASE_URL=postgresql://postgres.glnobjetjwzgkwqbjduy:123Rondoudou123@aws-1-eu-north-1.pooler.supabase.com:5432/postgres

# Stripe
STRIPE_API_KEY=sk_test_VOTRE_CLE_STRIPE
STRIPE_WEBHOOK_SECRET=
```

### Fichier `.env.local` du frontend (`storefront/.env.local`)
```env
MEDUSA_BACKEND_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_58dfaf8e246df51894b0c7291e70961ec094bb2ac7727493c072c1c71eaaec9f
NEXT_PUBLIC_BASE_URL=http://localhost:8000
NEXT_PUBLIC_DEFAULT_REGION=us
NEXT_PUBLIC_STRIPE_KEY=
NEXT_PUBLIC_MEDUSA_PAYMENTS_PUBLISHABLE_KEY=
NEXT_PUBLIC_MEDUSA_PAYMENTS_ACCOUNT_ID=
REVALIDATE_SECRET=supersecret
MEDUSA_CLOUD_S3_HOSTNAME=
MEDUSA_CLOUD_S3_PATHNAME=
```

### Commandes pour démarrer le projet (version finale)

**Backend (terminal 1)**
```bash
cd C:\Users\audif\Desktop\dicastri-medusa\medusa
npm run dev
```
✅ Backend disponible sur : http://localhost:9000

**Frontend (terminal 2)**
```bash
cd C:\Users\audif\Desktop\dicastri-medusa\storefront
npm run dev
```
✅ Frontend disponible sur : http://localhost:8000

---

## Checklist complète d'installation (pour la prochaine fois)

### 1. Créer le backend Medusa
```bash
cd C:\Users\audif\Desktop\dicastri-medusa
npx create-medusa-app@latest medusa --skip-db --skip-env
```

### 2. Configurer Supabase
- Créer un projet Supabase
- **Important** : Changer le mot de passe sans caractères spéciaux complexes
- Copier la **Session Pooler connection string**
- Format : `postgresql://postgres.PROJECT_ID:PASSWORD@aws-X-region.pooler.supabase.com:5432/postgres`

### 3. Configurer le backend
Créer `medusa/.env` :
```env
DATABASE_URL=postgresql://postgres.PROJECT_ID:PASSWORD@aws-X-region.pooler.supabase.com:5432/postgres
MEDUSA_ADMIN_ONBOARDING_TYPE=default
STORE_CORS=http://localhost:8000,https://docs.medusajs.com
ADMIN_CORS=http://localhost:5173,http://localhost:9000,https://docs.medusajs.com
AUTH_CORS=http://localhost:5173,http://localhost:9000,http://localhost:8000,https://docs.medusajs.com
REDIS_URL=redis://localhost:6379
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret
STRIPE_API_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=
```

### 4. Exécuter les migrations
```bash
cd medusa
npx medusa db:migrate
```

### 5. Lancer le backend
```bash
npm run dev
```
✅ Vérifier : http://localhost:9000

### 6. Créer l'utilisateur admin
```bash
npx medusa user -e votre@email.com -p VotreMotDePasse
```

### 7. Se connecter et créer une Publishable API Key
- Aller sur http://localhost:9000
- Se connecter avec les identifiants créés
- **Settings** → **Publishable API Keys** → Créer ou copier la clé

### 8. Cloner le storefront Next.js
```bash
cd C:\Users\audif\Desktop\dicastri-medusa
git clone https://github.com/medusajs/nextjs-starter-medusa storefront
```

### 9. Installer les dépendances du frontend
```bash
cd storefront
npm install
```

### 10. Configurer le frontend
Créer `storefront/.env.local` (copier depuis `.env.template`) :
```env
MEDUSA_BACKEND_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_... (votre clé)
NEXT_PUBLIC_BASE_URL=http://localhost:8000
NEXT_PUBLIC_DEFAULT_REGION=us
REVALIDATE_SECRET=supersecret
```

### 11. Lancer le frontend
```bash
npm run dev
```
✅ Vérifier : http://localhost:8000

### 12. (Optionnel) Ajouter des données de test
```bash
cd medusa
npm run seed
```

**Note** : Si le seed échoue avec "already exists", c'est normal. Vérifier que les régions existent :
```bash
npx medusa exec ./src/scripts/fix-regions.ts
```

---

## Étapes de déploiement (à venir)

### Frontend (Vercel)
1. Pusher le code sur GitHub
2. Connecter le repo à Vercel
3. Configurer les variables d'environnement
4. Déployer

### Backend (Railway/Render)
1. Créer un nouveau projet
2. Connecter le repo backend
3. Configurer les variables d'environnement
4. Ajouter PostgreSQL (ou utiliser Supabase)
5. Déployer

---

## Notes importantes

1. **Redis** : Message "fake redis instance will be used" est normal en développement
2. **Session Pooler** : Obligatoire pour Medusa avec Supabase (pas Direct Connection)
3. **Mot de passe** : Éviter les caractères spéciaux complexes (`*`, `^`, `&`) pour faciliter la saisie
4. **Migrations** : Toujours exécuter `npx medusa db:migrate` après modification du schéma
5. **Structure des dossiers** : `medusa/` = backend, `storefront/` = frontend
6. **Publishable Key** : Obligatoire pour que le frontend communique avec le backend
7. **Redémarrage** : Toujours redémarrer le frontend après modification du `.env.local`
8. **Deux terminaux** : Un pour le backend (port 9000), un pour le frontend (port 8000)
9. **Seed partiel** : Si le seed échoue, vérifier les régions avec le script `fix-regions.ts`
10. **Admin sans Sign Up** : Toujours créer l'admin via CLI avec `npx medusa user`
