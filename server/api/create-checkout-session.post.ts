import Stripe from 'stripe'
import { serverSupabaseClient } from '#supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16'
})

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const client = await serverSupabaseClient(event)

  try {
    // Get ticket types for pricing
    const { data: ticketTypes } = await client
      .from('ticket_types')
      .select('id, name, price')
      .in('id', Object.keys(body.tickets))

    if (!ticketTypes) throw new Error('Ticket types not found')

    // Create line items for Stripe
    const lineItems = ticketTypes.map(type => ({
      price_data: {
        currency: 'usd',
        product_data: {
          name: `${type.name} - ${body.concertName}`,
        },
        unit_amount: Math.round(type.price * 100), // Convert to cents
      },
      quantity: body.tickets[type.id],
    }))

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: lineItems,
      mode: 'payment',
      success_url: `${process.env.PUBLIC_URL}/tickets?success=true`,
      cancel_url: `${process.env.PUBLIC_URL}/tickets?canceled=true`,
      metadata: {
        orderId: body.orderId
      }
    })

    // Update order with payment intent
    await client
      .from('orders')
      .update({ payment_intent_id: session.payment_intent })
      .eq('id', body.orderId)

    return { sessionId: session.id }
  } catch (error) {
    console.error('Error creating checkout session:', error)
    throw createError({
      statusCode: 500,
      message: 'Error creating checkout session'
    })
  }
})