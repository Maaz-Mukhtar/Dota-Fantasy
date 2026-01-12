export const configuration = () => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  // Supabase configuration
  supabase: {
    url: process.env.SUPABASE_URL,
    anonKey: process.env.SUPABASE_ANON_KEY,
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  },

  // JWT configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'default-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  // External APIs
  stratz: {
    apiToken: process.env.STRATZ_API_TOKEN,
    apiUrl: 'https://api.stratz.com/graphql',
  },

  liquipedia: {
    apiKey: process.env.LIQUIPEDIA_API_KEY,
    apiUrl: 'https://liquipedia.net/dota2/api.php',
  },

  // Feature flags
  features: {
    enableLiveScores: process.env.ENABLE_LIVE_SCORES === 'true',
    enablePremium: process.env.ENABLE_PREMIUM === 'true',
  },
});

export type AppConfig = ReturnType<typeof configuration>;
