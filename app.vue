<template>
  <div class="min-h-screen bg-gradient-to-br from-black to-purple-900 text-white">
    <header class="fixed w-full bg-black/30 backdrop-blur-lg border-b border-white/10 z-50">
      <nav class="container mx-auto px-4 py-4 flex items-center justify-between">
        <NuxtLink to="/" class="text-2xl font-bold font-space-grotesk">
          Future<span class="text-purple-400">Concerts</span>
        </NuxtLink>
        <div class="flex items-center gap-6">
          <NuxtLink to="/concerts" class="hover:text-purple-400 transition">Concerts</NuxtLink>
          <NuxtLink to="/tickets" class="hover:text-purple-400 transition">My Tickets</NuxtLink>
          <template v-if="user">
            <button @click="logout" class="px-4 py-2 rounded-full bg-purple-600 hover:bg-purple-700 transition">
              Logout
            </button>
          </template>
          <template v-else>
            <button @click="login" class="px-4 py-2 rounded-full bg-purple-600 hover:bg-purple-700 transition">
              Login
            </button>
          </template>
        </div>
      </nav>
    </header>

    <main class="pt-20">
      <NuxtPage />
    </main>

    <footer class="bg-black/30 backdrop-blur-lg border-t border-white/10 mt-20">
      <div class="container mx-auto px-4 py-8">
        <div class="text-center text-sm text-gray-400">
          © {{ new Date().getFullYear() }} FutureConcerts. All rights reserved.
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
const user = useSupabaseUser()
const client = useSupabaseClient()

const login = async () => {
  const { error } = await client.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/auth/callback`
    }
  })
  if (error) {
    console.error('Error logging in:', error.message)
  }
}

const logout = async () => {
  const { error } = await client.auth.signOut()
  if (error) {
    console.error('Error logging out:', error.message)
  }
}
</script>

<style>
.font-space-grotesk {
  font-family: 'Space Grotesk', sans-serif;
}
</style>