<template>
  <div>
    <!-- Hero Section -->
    <section class="relative h-screen flex items-center justify-center overflow-hidden">
      <div class="absolute inset-0 z-0">
        <div class="absolute inset-0 bg-gradient-to-r from-purple-900/80 to-black/80"></div>
        <img src="https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?ixlib=rb-4.0.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1950&q=80" 
             class="w-full h-full object-cover" alt="Concert background">
      </div>
      
      <div class="relative z-10 text-center px-4">
        <h1 class="text-6xl md:text-8xl font-bold font-space-grotesk mb-6 animate-fade-in">
          Future<span class="text-purple-400">Concerts</span>
        </h1>
        <p class="text-xl md:text-2xl mb-8 text-gray-300 max-w-2xl mx-auto">
          Experience the future of concert ticketing. Secure, seamless, and unforgettable.
        </p>
        <NuxtLink to="/concerts" 
                  class="inline-block px-8 py-4 bg-purple-600 hover:bg-purple-700 rounded-full text-lg font-semibold transition-all transform hover:scale-105">
          Explore Concerts
        </NuxtLink>
      </div>
    </section>

    <!-- Featured Concerts -->
    <section class="container mx-auto px-4 py-20">
      <h2 class="text-4xl font-bold mb-12 text-center font-space-grotesk">Featured Events</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        <div v-for="concert in featuredConcerts" :key="concert.id" 
             class="bg-white/5 rounded-xl overflow-hidden hover:transform hover:scale-105 transition-all duration-300">
          <img :src="concert.image_url" :alt="concert.name" class="w-full h-48 object-cover">
          <div class="p-6">
            <h3 class="text-xl font-bold mb-2">{{ concert.name }}</h3>
            <p class="text-gray-400 mb-4">{{ concert.artist }}</p>
            <div class="flex justify-between items-center">
              <span class="text-purple-400">{{ formatDate(concert.date) }}</span>
              <NuxtLink :to="`/concerts/${concert.id}`" 
                        class="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-full text-sm font-semibold">
                View Details
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
const client = useSupabaseClient()

const featuredConcerts = ref([])

onMounted(async () => {
  const { data, error } = await client
    .from('concerts')
    .select('*')
    .limit(6)
    .order('date', { ascending: true })
  
  if (error) {
    console.error('Error fetching concerts:', error.message)
    return
  }
  
  featuredConcerts.value = data
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  })
}
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 1s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>