export default defineNuxtConfig({
  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
    '@vueuse/nuxt',
    '@nuxtjs/google-fonts'
  ],

  supabase: {
    url: process.env.VITE_SUPABASE_URL,
    key: process.env.VITE_SUPABASE_ANON_KEY,
    redirect: false,
    redirectOptions: {
      login: '/auth/login',
      callback: '/auth/callback',
      exclude: ['/*']
    }
  },

  googleFonts: {
    families: {
      'Space+Grotesk': [300, 400, 500, 600, 700],
      'Inter': [100, 200, 300, 400, 500, 600, 700]
    }
  },

  app: {
    head: {
      title: 'Future Concerts',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Experience the future of concert ticketing' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
      ]
    }
  },

  runtimeConfig: {
    public: {
      stripePublicKey: process.env.STRIPE_PUBLIC_KEY
    },
    private: {
      stripeSecretKey: process.env.STRIPE_SECRET_KEY
    }
  },

  compatibilityDate: '2025-02-02'
})