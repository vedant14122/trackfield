import { serve } from 'std/server'
import Stripe from 'stripe'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2022-11-15' })

serve(async (req) => {
  const { email, priceId } = await req.json()

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    mode: 'subscription',
    customer_email: email,
    line_items: [
      {
        price: priceId, // Pass your Stripe Price ID from the client or hardcode it here
        quantity: 1,
      },
    ],
    success_url: 'https://your-app.com/success',
    cancel_url: 'https://your-app.com/cancel',
  })

  return new Response(JSON.stringify({ url: session.url }), {
    headers: { 'Content-Type': 'application/json' }
  })
}) 