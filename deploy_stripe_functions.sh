#!/bin/bash

# Stripe Edge Functions Deployment Script
# This script helps deploy the Stripe subscription functions to Supabase

echo "🚀 Deploying Stripe Edge Functions to Supabase..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Navigate to the frontend directory
cd athlete_form_ai/frontend

# Check if project is linked
if [ ! -f ".supabase/config.toml" ]; then
    echo "🔗 Linking to Supabase project..."
    supabase link --project-ref qbrznwagzojfrazmwkjf
fi

# Deploy the create-subscription-session function
echo "📦 Deploying create-subscription-session function..."
supabase functions deploy create-subscription-session

# Deploy the stripe-webhook function
echo "📦 Deploying stripe-webhook function..."
supabase functions deploy stripe-webhook

echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Set up your Stripe products and prices (see STRIPE_SETUP_GUIDE.md)"
echo "2. Configure environment variables in Supabase Dashboard"
echo "3. Set up Stripe webhooks"
echo "4. Test the integration"
echo ""
echo "🔗 Supabase Dashboard: https://supabase.com/dashboard/project/qbrznwagzojfrazmwkjf"
echo "🔗 Stripe Dashboard: https://dashboard.stripe.com" 