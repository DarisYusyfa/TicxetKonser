<template>
  <div class="container mx-auto px-4 py-12">
    <h1 class="text-4xl font-bold mb-8 font-space-grotesk">My Tickets</h1>

    <div v-if="!user" class="text-center py-12">
      <p class="text-xl text-gray-400 mb-4">Please login to view your tickets</p>
      <button @click="login" 
              class="px-6 py-3 bg-purple-600 hover:bg-purple-700 rounded-full font-semibold">
        Login
      </button>
    </div>

    <div v-else>
      <!-- Active Tickets -->
      <div class="space-y-6">
        <h2 class="text-2xl font-semibold">Active Tickets</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div v-for="ticket in activeTickets" :key="ticket.id" 
               class="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-purple-500/30">
            <div class="mb-4">
              <h3 class="text-xl font-semibold">{{ ticket.concert.name }}</h3>
              <p class="text-purple-400">{{ ticket.concert.artist }}</p>
            </div>
            <div class="space-y-2 text-gray-300">
              <div class="flex items-center gap-2">
                <CalendarIcon class="w-5 h-5" />
                <span>{{ formatDate(ticket.concert.date) }}</span>
              </div>
              <div class="flex items-center gap-2">
                <MapPinIcon class="w-5 h-5" />
                <span>{{ ticket.concert.venue }}</span>
              </div>
              <div class="flex items-center gap-2">
                <TicketIcon class="w-5 h-5" />
                <span>{{ ticket.ticket_type.name }}</span>
              </div>
            </div>
            <div class="mt-4">
              <img :src="ticket.qr_code" alt="Ticket QR Code" 
                   class="w-full max-w-[200px] mx-auto">
            </div>
          </div>
        </div>
      </div>

      <!-- Past Tickets -->
      <div class="mt-12 space-y-6">
        <h2 class="text-2xl font-semibold">Past Events</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div v-for="ticket in pastTickets" :key="ticket.id" 
               class="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-gray-500/30 opacity-75">
            <div class="mb-4">
              <h3 class="text-xl font-semibold">{{ ticket.concert.name }}</h3>
              <p class="text-purple-400">{{ ticket.concert.artist }}</p>
            </div>
            <div class="space-y-2 text-gray-300">
              <div class="flex items-center gap-2">
                <CalendarIcon class="w-5 h-5" />
                <span>{{ formatDate(ticket.concert.date) }}</span>
              </div>
              <div class="flex items-center gap-2">
                <MapPinIcon class="w-5 h-5" />
                <span>{{ ticket.concert.venue }}</span>
              </div>
              <div class="flex items-center gap-2">
                <TicketIcon class="w-5 h-5" />
                <span>{{ ticket.ticket_type.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { CalendarIcon, MapPinIcon, TicketIcon } from '@heroicons/vue/24/outline'

const client = useSupabaseClient()
const user = useSupabaseUser()

const activeTickets = ref([])
const pastTickets = ref([])

onMounted(async () => {
  if (!user.value) return

  const now = new Date().toISOString()

  const { data: tickets, error } = await client
    .from('tickets')
    .select(`
      *,
      ticket_type:ticket_types(*),
      concert:ticket_types(concert:concerts(*))
    `)
    .eq('user_id', user.value.id)
    .eq('status', 'active')

  if (error) {
    console.error('Error fetching tickets:', error.message)
    return
  }

  // Split tickets into active and past
  activeTickets.value = tickets.filter(ticket => 
    new Date(ticket.concert.concert.date) >= new Date()
  )
  pastTickets.value = tickets.filter(ticket => 
    new Date(ticket.concert.concert.date) < new Date()
  )
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  })
}

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
</script>