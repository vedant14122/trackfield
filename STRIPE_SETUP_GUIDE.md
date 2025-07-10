# Stripe Subscription Setup Guide

## 1. Create Stripe Products and Prices

### Step 1: Log into Stripe Dashboard
1. Go to [dashboard.stripe.com](https://dashboard.stripe.com)
2. Navigate to **Products** in the left sidebar

### Step 2: Create Products
Create the following products:

#### Product 1: Dash AI
- **Name**: Dash AI
- **Description**: Standard monthly subscription for track & field analysis
- **Type**: Service

#### Product 2: Dash AI Presale
- **Name**: Dash AI Presale
- **Description**: Special presale offer for early adopters
- **Type**: Service

#### Product 3: Dash AI Beta Tester
- **Name**: Dash AI Beta Tester Discount
- **Description**: Discounted subscription for beta testers
- **Type**: Service

### Step 3: Create Prices for Each Product

For each product, create a recurring price:

#### Dash AI Price
- **Pricing model**: Standard pricing
- **Price**: $5.99 USD
- **Billing period**: Monthly
- **Currency**: USD
- **Copy the Price ID** (starts with `price_`)

#### Dash AI Presale Price
- **Pricing model**: Standard pricing
- **Price**: $4.99 USD
- **Billing period**: Monthly
- **Currency**: USD
- **Copy the Price ID** (starts with `price_`)

#### Dash AI Beta Tester Price
- **Pricing model**: Standard pricing
- **Price**: $4.59 USD
- **Billing period**: Monthly
- **Currency**: USD
- **Copy the Price ID** (starts with `price_`)

### Step 4: Update Your Code
Replace the Price IDs in `lib/subscription_page.dart`:

```dart
// Replace these with your actual Stripe Price IDs
static const String dashAiPriceId = 'price_YOUR_DASH_AI_PRICE_ID';
static const String dashAiPresalePriceId = 'price_YOUR_PRESALE_PRICE_ID';
static const String dashAiBetaPriceId = 'price_YOUR_BETA_PRICE_ID';
```

## 2. Set Up Stripe Webhooks

### Step 1: Create Webhook Endpoint
1. In Stripe Dashboard, go to **Developers** → **Webhooks**
2. Click **Add endpoint**
3. **Endpoint URL**: `https://qbrznwagzojfrazmwkjf.functions.supabase.co/functions/v1/stripe-webhook`
4. **Events to send**: Select these events:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
5. Click **Add endpoint**

### Step 2: Get Webhook Secret
1. After creating the webhook, click on it
2. Click **Reveal** next to the signing secret
3. Copy the webhook secret (starts with `whsec_`)

## 3. Configure Supabase Environment Variables

### Step 1: Add Stripe Environment Variables
In your Supabase project dashboard:

1. Go to **Settings** → **Edge Functions**
2. Add these environment variables:

```
STRIPE_SECRET_KEY=sk_test_YOUR_STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET
SUPABASE_URL=https://qbrznwagzojfrazmwkjf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

### Step 2: Get Your Stripe Secret Key
1. In Stripe Dashboard, go to **Developers** → **API keys**
2. Copy the **Secret key** (starts with `sk_test_` for test mode)

### Step 3: Get Your Supabase Service Role Key
1. In Supabase Dashboard, go to **Settings** → **API**
2. Copy the **service_role** key (starts with `eyJ`)

## 4. Deploy Edge Functions

### Step 1: Install Supabase CLI (if not already installed)
```bash
npm install -g supabase
```

### Step 2: Login to Supabase
```bash
supabase login
```

### Step 3: Link Your Project
```bash
cd athlete_form_ai/frontend
supabase link --project-ref qbrznwagzojfrazmwkjf
```

### Step 4: Deploy Functions
```bash
supabase functions deploy create-subscription-session
supabase functions deploy stripe-webhook
```

## 5. Test the Integration

### Step 1: Test Checkout Session
1. Run your Flutter app
2. Navigate to the subscription page
3. Click on a subscription plan
4. Verify that Stripe Checkout opens

### Step 2: Test Webhook
1. Complete a test payment in Stripe Checkout
2. Check your Supabase database to verify the profile was updated
3. Check the Edge Function logs in Supabase Dashboard

## 6. Production Setup

### Step 1: Switch to Live Mode
1. In Stripe Dashboard, toggle to **Live** mode
2. Create new products and prices in live mode
3. Update your Price IDs in the code
4. Update your environment variables with live keys

### Step 2: Update Webhook URL
1. Update the webhook endpoint URL to your production domain
2. Test the webhook with live payments

## 7. Security Best Practices

1. **Never expose secret keys** in client-side code
2. **Use environment variables** for all sensitive data
3. **Verify webhook signatures** (already implemented in the code)
4. **Handle webhook failures** gracefully
5. **Monitor webhook delivery** in Stripe Dashboard

## 8. Troubleshooting

### Common Issues:

1. **"No host specified in URI"**: Check your Supabase URL format
2. **"Connection failed"**: Verify your Supabase project is active
3. **Webhook signature verification failed**: Check your webhook secret
4. **Function deployment failed**: Check your environment variables

### Debug Steps:

1. Check Edge Function logs in Supabase Dashboard
2. Verify environment variables are set correctly
3. Test webhook endpoint with Stripe CLI
4. Check browser console for client-side errors

## 9. Stripe CLI (Optional but Recommended)

Install Stripe CLI for local testing:

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local development
stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
```

This will help you test webhooks locally during development. 