import { serve } from 'std/server'
import Stripe from 'stripe'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2022-11-15' })

serve(async (req) => {
  const sig = req.headers.get('stripe-signature')!
  const body = await req.text()
  let event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    const email = session.customer_email
    const stripeCustomerId = session.customer as string
    const subscriptionId = session.subscription as string
    // Stripe Checkout Session API may differ, adjust as needed
    const priceId = session.items?.data[0]?.price?.id || null

    // Update Supabase profile
    const supabaseAdminKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    await fetch('https://<your-project-ref>.supabase.co/rest/v1/profiles?email=eq.' + email, {
      method: 'PATCH',
      headers: {
        'apikey': supabaseAdminKey,
        'Authorization': 'Bearer ' + supabaseAdminKey,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        stripe_customer_id: stripeCustomerId,
        stripe_subscription_id: subscriptionId,
        subscription_status: 'active',
        stripe_price_id: priceId
      })
    })
  }

  // You can handle more events here (subscription.updated, deleted, etc.)

  return new Response('ok', { status: 200 })
}) 