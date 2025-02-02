<script setup>
const user = useSupabaseUser()
const { auth } = useSupabaseClient()

// Handle the OAuth callback
watchEffect(async () => {
  try {
    const { error } = await auth.getSession()
    if (error) throw error
    
    // Redirect to home page after successful login
    await navigateTo('/')
  } catch (error) {
    console.error('Error in auth callback:', error)
    await navigateTo('/auth/login')
  }
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center">
    <div class="text-center">
      <h2 class="text-2xl font-bold mb-4">Logging you in...</h2>
      <div class="w-16 h-16 border-4 border-purple-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
    </div>
  </div>
</template>