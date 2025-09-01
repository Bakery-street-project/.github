#!/usr/bin/env python3
"""
Stripe Automation Script for Baker Street Project
Automatically creates products and pricing tiers for BlackRock Analyzer
"""

import stripe
import os
from typing import Dict, List

# Configuration
STRIPE_SECRET_KEY = os.getenv('STRIPE_SECRET_KEY')
if not STRIPE_SECRET_KEY:
    print("❌ Error: Set STRIPE_SECRET_KEY environment variable")
    print("export STRIPE_SECRET_KEY='sk_test_...'")
    exit(1)

stripe.api_key = STRIPE_SECRET_KEY

# Product Configuration
PRODUCT_CONFIG = {
    "name": "BlackRock Analyzer",
    "description": "Advanced AI-powered regulatory compliance and risk analysis platform for financial institutions. Combines spiking neural networks, graph analytics, and regulatory expertise to deliver unprecedented insights into complex financial systems.",
    "metadata": {
        "product_type": "saas_platform",
        "ai_focus": "regulatory_compliance",
        "target_industry": "financial_services",
        "technology": "ai_neural_networks",
        "company_name": "Baker Street Project",
        "website": "https://bakerstreet-project.com",
        "support_email": "sherlock@bakerstreet-project.com"
    }
}

# Pricing Tiers Configuration
PRICING_TIERS = [
    {
        "name": "Starter",
        "price": 29.00,
        "currency": "usd",
        "billing": "month",
        "lookup_key": "blackrock_analyzer_starter_monthly",
        "description": "blackrock-analyzer-starter-monthly",
        "features": [
            "Basic Entity Analysis (50 entities/month)",
            "API Access (1,000 calls/month)",
            "Standard Risk Detection",
            "Basic Compliance Reports",
            "Email Support",
            "CSV Data Export",
            "Web Dashboard Access",
            "Mobile Responsive Interface"
        ]
    },
    {
        "name": "Growth",
        "price": 79.00,
        "currency": "usd",
        "billing": "month",
        "lookup_key": "blackrock_analyzer_growth_monthly",
        "description": "blackrock-analyzer-growth-monthly",
        "features": [
            "Advanced Entity Analysis (500 entities/month)",
            "Increased API Access (10,000 calls/month)",
            "AI-Powered Risk Detection",
            "Advanced Compliance Reports",
            "Priority Support (Email + Chat)",
            "Multiple Export Formats (CSV, JSON, Excel)",
            "Custom Report Templates",
            "API Rate Limiting"
        ]
    },
    {
        "name": "Professional",
        "price": 199.00,
        "currency": "usd",
        "billing": "month",
        "lookup_key": "blackrock_analyzer_professional_monthly",
        "description": "blackrock-analyzer-professional-monthly",
        "features": [
            "Unlimited Entity Analysis",
            "Unlimited API Access",
            "Full Regulatory Compliance (SEC, FCA, International)",
            "Custom Compliance Reports",
            "Dedicated Support (Phone + Email + Chat)",
            "White-label Reports",
            "Advanced Analytics Dashboard",
            "Custom Integrations",
            "SLA Guarantees"
        ]
    },
    {
        "name": "Enterprise",
        "price": 499.00,
        "currency": "usd",
        "billing": "month",
        "lookup_key": "blackrock_analyzer_enterprise_monthly",
        "description": "blackrock-analyzer-enterprise-monthly",
        "features": [
            "Everything in Professional +",
            "Custom API Integrations",
            "White-label Solutions",
            "Dedicated Account Manager",
            "Custom Training Programs",
            "On-premise Deployment Options",
            "Advanced Security Features",
            "Custom Development",
            "99.9% Uptime SLA",
            "Priority Feature Development"
        ]
    }
]

def create_product():
    """Create the main product in Stripe"""
    try:
        print("🏗️ Creating BlackRock Analyzer product...")
        
        product = stripe.Product.create(
            name=PRODUCT_CONFIG["name"],
            description=PRODUCT_CONFIG["description"],
            metadata=PRODUCT_CONFIG["metadata"]
        )
        
        print(f"✅ Product created successfully!")
        print(f"   Product ID: {product.id}")
        print(f"   Name: {product.name}")
        print(f"   Description: {product.description[:100]}...")
        
        return product.id
        
    except stripe.error.StripeError as e:
        print(f"❌ Error creating product: {e}")
        return None

def create_price(product_id: str, tier: Dict):
    """Create a pricing tier for the product"""
    try:
        print(f"💰 Creating {tier['name']} tier (${tier['price']}/{tier['billing']})...")
        
        # Convert price to cents
        unit_amount = int(tier['price'] * 100)
        
        price = stripe.Price.create(
            unit_amount=unit_amount,
            currency=tier['currency'],
            recurring={'interval': tier['billing']},
            product=product_id,
            lookup_key=tier['lookup_key'],
            metadata={
                'description': tier['description'],
                'features': '; '.join(tier['features']),
                'tier_name': tier['name']
            }
        )
        
        print(f"✅ {tier['name']} tier created successfully!")
        print(f"   Price ID: {price.id}")
        print(f"   Lookup Key: {price.lookup_key}")
        print(f"   Amount: ${tier['price']}/{tier['billing']}")
        
        return price.id
        
    except stripe.error.StripeError as e:
        print(f"❌ Error creating {tier['name']} tier: {e}")
        return None

def create_payment_links():
    """Create payment links for each tier"""
    try:
        print("🔗 Creating payment links...")
        
        # Get all prices
        prices = stripe.Price.list(limit=100)
        
        for price in prices.data:
            if price.lookup_key and 'blackrock_analyzer' in price.lookup_key:
                print(f"📱 Creating payment link for {price.lookup_key}...")
                
                payment_link = stripe.PaymentLink.create(
                    line_items=[{
                        'price': price.id,
                        'quantity': 1,
                    }],
                    after_completion={'type': 'redirect', 'redirect': {'url': 'https://bakerstreet-project.com/success'}},
                    metadata={
                        'product': 'blackrock_analyzer',
                        'tier': price.lookup_key
                    }
                )
                
                print(f"✅ Payment link created: {payment_link.url}")
        
    except stripe.error.StripeError as e:
        print(f"❌ Error creating payment links: {e}")

def main():
    """Main automation function"""
    print("🚀 Baker Street Project - Stripe Automation")
    print("=" * 50)
    
    # Check if we're in test mode
    if 'test' in STRIPE_SECRET_KEY:
        print("🧪 Running in TEST mode")
    else:
        print("🚨 Running in LIVE mode")
    
    print()
    
    # Create product
    product_id = create_product()
    if not product_id:
        print("❌ Failed to create product. Exiting.")
        return
    
    print()
    
    # Create pricing tiers
    created_prices = []
    for tier in PRICING_TIERS:
        price_id = create_price(product_id, tier)
        if price_id:
            created_prices.append(price_id)
        print()
    
    print(f"✅ Created {len(created_prices)} pricing tiers")
    
    # Create payment links
    print()
    create_payment_links()
    
    print()
    print("🎉 Stripe automation complete!")
    print("=" * 50)
    print("Next steps:")
    print("1. Test the payment links")
    print("2. Update your GitHub profile with payment links")
    print("3. Start marketing your BlackRock Analyzer")
    print("4. Monitor Stripe dashboard for payments")

if __name__ == "__main__":
    main()
