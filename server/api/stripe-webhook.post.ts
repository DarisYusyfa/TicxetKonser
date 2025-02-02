import Stripe from 'stripe'
import { serverSupabaseClient } from '#supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16'
})

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event)
  const sig = getHeader(event, 'stripe-signature')

  let stripeEvent

  try {
    stripeEvent = stripe.webhooks.constructEvent(body!, sig!, endpointSecret!)
  } catch (err) {
    throw createError({
      statusCode: 400,
      message: `Webhook Error: ${err instanceof Error ? err.message : 'Unknown error'}`
    })
  }

  const client = await serverSupabaseClient(event)

  if (stripeEvent.type === 'payment_intent.succeeded') {
    const paymentIntent = stripeEvent.data.object as Stripe.PaymentIntent
    
    // Update order and tickets status
    await client
      .from('orders')
      .update({ status: 'completed' })
      .eq('payment_intent_id', paymentIntent.id)

    const { data: order } = await client
      .from('orders')
      .select('id')
      .eq('payment_intent_id', paymentIntent.id)
      .single()

    if (order) {
      await client
        .from('tickets')
        .update({ 
          status: 'active',
          qr_code: generateQRCode(order.id) // Implement QR code generation
        })
        .eq('order_id', order.id)
    }
  }

  return { received: true }
})