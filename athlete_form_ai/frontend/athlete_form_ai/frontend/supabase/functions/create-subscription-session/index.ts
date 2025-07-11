import { serve } from 'std/server'
import Stripe from 'stripe'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2022-11-15' })

serve(async (req) => {
  try {
    const { email, priceId } = await req.json()

    if (!email || !priceId) {
      return new Response(
        JSON.stringify({ error: 'Email and priceId are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'subscription',
      customer_email: email,
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: `${req.headers.get('origin')}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${req.headers.get('origin')}/cancel`,
      metadata: {
        email: email,
        priceId: priceId,
      },
    })

    return new Response(
      JSON.stringify({ url: session.url }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error creating checkout session:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to create checkout session' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
