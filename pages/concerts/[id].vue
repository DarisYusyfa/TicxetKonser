<template>
  <div class="container mx-auto px-4 py-12">
    <div v-if="concert" class="grid grid-cols-1 lg:grid-cols-2 gap-12">
      <!-- Concert Image and Info -->
      <div class="space-y-6">
        <img :src="concert.image_url" :alt="concert.name" 
             class="w-full h-96 object-cover rounded-2xl shadow-2xl">
        <div class="bg-white/5 backdrop-blur-lg rounded-2xl p-6 space-y-4">
          <h1 class="text-4xl font-bold font-space-grotesk">{{ concert.name }}</h1>
          <p class="text-2xl text-purple-400">{{ concert.artist }}</p>
          <div class="flex items-center gap-4 text-gray-300">
            <CalendarIcon class="w-6 h-6" />
            <span>{{ formatDate(concert.date) }}</span>
          </div>
          <div class="flex items-center gap-4 text-gray-300">
            <MapPinIcon class="w-6 h-6" />
            <span>{{ concert.venue }}</span>
          </div>
          <p class="text-gray-300">{{ concert.description }}</p>
        </div>
      </div>

      <!-- Ticket Selection -->
      <div class="bg-white/5 backdrop-blur-lg rounded-2xl p-6">
        <h2 class="text-2xl font-bold mb-6 font-space-grotesk">Select Tickets</h2>
        <div class="space-y-4">
          <div v-for="type in ticketTypes" :key="type.id" 
               class="border border-purple-500/30 rounded-xl p-4 space-y-4">
            <div class="flex justify-between items-center">
              <div>
                <h3 class="text-xl font-semibold">{{ type.name }}</h3>
                <p class="text-purple-400">${{ type.price }}</p>
              </div>
              <div class="flex items-center gap-4">
                <button @click="decrementTicket(type.id)" 
                        class="w-8 h-8 rounded-full bg-purple-600/50 hover:bg-purple-600 flex items-center justify-center">
                  <MinusIcon class="w-4 h-4" />
                </button>
                <span>{{ selectedTickets[type.id] || 0 }}</span>
                <button @click="incrementTicket(type.id)" 
                        class="w-8 h-8 rounded-full bg-purple-600/50 hover:bg-purple-600 flex items-center justify-center"
                        :disabled="type.quantity_available <= (type.quantity_sold + (selectedTickets[type.id] || 0))">
                  <PlusIcon class="w-4 h-4" />
                </button>
              </div>
            </div>
            <div class="text-sm text-gray-400">
              <div>Available: {{ type.quantity_available - type.quantity_sold }}</div>
              <div class="mt-2">Benefits:</div>
              <ul class="list-disc list-inside">
                <li v-for="benefit in type.benefits" :key="benefit">{{ benefit }}</li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Order Summary -->
        <div class="mt-8 border-t border-purple-500/30 pt-6">
          <h3 class="text-xl font-semibold mb-4">Order Summary</h3>
          <div class="space-y-2">
            <div v-for="type in ticketTypes" :key="type.id">
              <div v-if="selectedTickets[type.id]" class="flex justify-between">
                <span>{{ type.name }} × {{ selectedTickets[type.id] }}</span>
                <span>${{ (type.price * selectedTickets[type.id]).toFixed(2) }}</span>
              </div>
            </div>
            <div class="border-t border-purple-500/30 pt-2 mt-4">
              <div class="flex justify-between font-semibold">
                <span>Total</span>
                <span>${{ totalAmount.toFixed(2) }}</span>
              </div>
            </div>
          </div>

          <button @click="checkout" 
                  :disabled="!hasTickets || !user"
                  class="w-full mt-6 px-6 py-3 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 
                         rounded-full font-semibold transition-colors">
            {{ user ? 'Proceed to Payment' : 'Login to Purchase' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { CalendarIcon, MapPinIcon, MinusIcon, PlusIcon } from '@heroicons/vue/24/outline'

const route = useRoute()
const client = useSupabaseClient()
const user = useSupabaseUser()
const stripe = useStripe()

const concert = ref(null)
const ticketTypes = ref([])
const selectedTickets = ref({})

// Fetch concert and ticket types
onMounted(async () => {
  const { data: concertData, error: concertError } = await client
    .from('concerts')
    .select('*')
    .eq('id', route.params.id)
    .single()

  if (concertError) {
    console.error('Error fetching concert:', concertError.message)
    return
  }

  concert.value = concertData

  const { data: ticketData, error: ticketError } = await client
    .from('ticket_types')
    .select('*')
    .eq('concert_id', route.params.id)

  if (ticketError) {
    console.error('Error fetching ticket types:', ticketError.message)
    return
  }

  ticketTypes.value = ticketData
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

const incrementTicket = (typeId) => {
  const currentAmount = selectedTickets.value[typeId] || 0
  const ticketType = ticketTypes.value.find(t => t.id === typeId)
  
  if (ticketType.quantity_available > (ticketType.quantity_sold + currentAmount)) {
    selectedTickets.value[typeId] = currentAmount + 1
  }
}

const decrementTicket = (typeId) => {
  const currentAmount = selectedTickets.value[typeId] || 0
  if (currentAmount > 0) {
    selectedTickets.value[typeId] = currentAmount - 1
  }
}

const totalAmount = computed(() => {
  return ticketTypes.value.reduce((total, type) => {
    return total + (type.price * (selectedTickets.value[type.id] || 0))
  }, 0)
})

const hasTickets = computed(() => {
  return Object.values(selectedTickets.value).some(amount => amount > 0)
})

const checkout = async () => {
  if (!user.value) return

  try {
    // Create order
    const { data: order, error: orderError } = await client
      .from('orders')
      .insert({
        user_id: user.value.id,
        total_amount: totalAmount.value,
        status: 'pending'
      })
      .select()
      .single()

    if (orderError) throw orderError

    // Create tickets
    const tickets = []
    for (const [typeId, quantity] of Object.entries(selectedTickets.value)) {
      for (let i = 0; i < quantity; i++) {
        tickets.push({
          order_id: order.id,
          ticket_type_id: typeId,
          user_id: user.value.id,
          status: 'pending'
        })
      }
    }

    const { error: ticketError } = await client
      .from('tickets')
      .insert(tickets)

    if (ticketError) throw ticketError

    // Create Stripe Checkout Session
    const response = await $fetch('/api/create-checkout-session', {
      method: 'POST',
      body: {
        orderId: order.id,
        tickets: selectedTickets.value,
        concertName: concert.value.name
      }
    })

    // Redirect to Stripe Checkout
    const { error: stripeError } = await stripe.redirectToCheckout({
      sessionId: response.sessionId
    })

    if (stripeError) throw stripeError

  } catch (error) {
    console.error('Error during checkout:', error)
    // Handle error (show error message to user)
  }
}
</script>