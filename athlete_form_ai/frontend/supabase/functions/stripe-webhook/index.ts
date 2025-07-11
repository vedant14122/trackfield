<<<<<<< HEAD
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
=======
import { serve } from 'std/server'
>>>>>>> fe80c0edfbb2ae52096ecaff5f46a490051e7482
import Stripe from 'stripe'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2022-11-15' })

serve(async (req) => {
<<<<<<< HEAD
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const sig = req.headers.get('stripe-signature')!
  const body = await req.text()
  let event: Stripe.Event
=======
  const sig = req.headers.get('stripe-signature')!
  const body = await req.text()
  let event
>>>>>>> fe80c0edfbb2ae52096ecaff5f46a490051e7482

  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )
  } catch (err) {
<<<<<<< HEAD
    console.error('Webhook signature verification failed:', err)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        const session = event.data.object as Stripe.Checkout.Session
        await handleCheckoutSessionCompleted(session)
        break

      case 'customer.subscription.updated':
        const subscription = event.data.object as Stripe.Subscription
        await handleSubscriptionUpdated(subscription)
        break

      case 'customer.subscription.deleted':
        const deletedSubscription = event.data.object as Stripe.Subscription
        await handleSubscriptionDeleted(deletedSubscription)
        break

      case 'invoice.payment_failed':
        const invoice = event.data.object as Stripe.Invoice
        await handlePaymentFailed(invoice)
        break

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response('ok', { status: 200 })
  } catch (error) {
    console.error('Error processing webhook:', error)
    return new Response('Webhook processing failed', { status: 500 })
  }
})

async function handleCheckoutSessionCompleted(session: Stripe.Checkout.Session) {
  const email = session.customer_email
  const stripeCustomerId = session.customer as string
  const subscriptionId = session.subscription as string
  const priceId = session.metadata?.priceId

  if (!email) {
    console.error('No email found in checkout session')
    return
  }

  // Update Supabase profile
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  
  const response = await fetch(`${supabaseUrl}/rest/v1/profiles?email=eq.${encodeURIComponent(email)}`, {
    method: 'PATCH',
    headers: {
      'apikey': supabaseServiceKey,
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      stripe_customer_id: stripeCustomerId,
      stripe_subscription_id: subscriptionId,
      subscription_status: 'active',
      stripe_price_id: priceId,
      updated_at: new Date().toISOString()
    })
  })

  if (!response.ok) {
    console.error('Failed to update profile:', await response.text())
  }
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string
  
  // Get customer email
  const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer
  const email = customer.email

  if (!email) {
    console.error('No email found for customer')
    return
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  
  const response = await fetch(`${supabaseUrl}/rest/v1/profiles?email=eq.${encodeURIComponent(email)}`, {
    method: 'PATCH',
    headers: {
      'apikey': supabaseServiceKey,
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      subscription_status: subscription.status,
      stripe_subscription_id: subscription.id,
      updated_at: new Date().toISOString()
    })
  })

  if (!response.ok) {
    console.error('Failed to update profile:', await response.text())
  }
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string
  
  // Get customer email
  const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer
  const email = customer.email

  if (!email) {
    console.error('No email found for customer')
    return
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  
  const response = await fetch(`${supabaseUrl}/rest/v1/profiles?email=eq.${encodeURIComponent(email)}`, {
    method: 'PATCH',
    headers: {
      'apikey': supabaseServiceKey,
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      subscription_status: 'canceled',
      stripe_subscription_id: null,
      updated_at: new Date().toISOString()
    })
  })

  if (!response.ok) {
    console.error('Failed to update profile:', await response.text())
  }
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const customerId = invoice.customer as string
  
  // Get customer email
  const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer
  const email = customer.email

  if (!email) {
    console.error('No email found for customer')
    return
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  
  const response = await fetch(`${supabaseUrl}/rest/v1/profiles?email=eq.${encodeURIComponent(email)}`, {
    method: 'PATCH',
    headers: {
      'apikey': supabaseServiceKey,
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      subscription_status: 'past_due',
      updated_at: new Date().toISOString()
    })
  })

  if (!response.ok) {
    console.error('Failed to update profile:', await response.text())
  }
}
=======
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
>>>>>>> fe80c0edfbb2ae52096ecaff5f46a490051e7482
