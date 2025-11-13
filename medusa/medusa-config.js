const { loadEnv, defineConfig } = require('@medusajs/framework/utils')

loadEnv(process.env.NODE_ENV || 'development', process.cwd())

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    http: {
      storeCors: process.env.STORE_CORS,
      adminCors: process.env.ADMIN_CORS,
      authCors: process.env.AUTH_CORS,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret",
      port: process.env.PORT || 9000,
    }
  },
  admin: {
    // Si MEDUSA_ADMIN_DISABLE='false' -> activé
    // Sinon -> désactivé
    disable: process.env.MEDUSA_ADMIN_DISABLE !== 'false'
  }
})
