#!/bin/bash

# Baker Street Project - Stripe Automation Setup
# This script sets up the Stripe automation environment

set -e

echo "🚀 Baker Street Project - Stripe Automation Setup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python 3 is installed
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Python $PYTHON_VERSION found"

# Check if pip is installed
print_status "Checking pip installation..."
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is not installed. Please install pip3 first."
    exit 1
fi

print_success "pip3 found"

# Create virtual environment
print_status "Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated"

# Install requirements
print_status "Installing Python dependencies..."
pip install -r stripe_requirements.txt
print_success "Dependencies installed"

# Install Stripe CLI
print_status "Installing Stripe CLI..."
if ! command -v stripe &> /dev/null; then
    # Download and install Stripe CLI
    curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
    echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
    sudo apt update
    sudo apt install -y stripe
    print_success "Stripe CLI installed"
else
    print_warning "Stripe CLI already installed"
fi

# Create .env template
print_status "Creating environment file template..."
cat > .env.template << EOF
# Stripe Configuration
# Copy this file to .env and fill in your actual values

# Your Stripe Secret Key (get this from https://dashboard.stripe.com/apikeys)
STRIPE_SECRET_KEY=sk_test_your_test_key_here

# For production, use your live key:
# STRIPE_SECRET_KEY=sk_live_your_live_key_here

# Optional: Webhook endpoint secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
EOF

print_success "Environment template created (.env.template)"

# Create run script
print_status "Creating run script..."
cat > run_stripe_automation.sh << 'EOF'
#!/bin/bash

# Baker Street Project - Stripe Automation Runner
# This script runs the Stripe automation

set -e

echo "🚀 Running Stripe Automation..."
echo "================================"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy .env.template to .env and fill in your Stripe keys"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Run the automation script
python3 stripe_automation.py

echo ""
echo "✅ Stripe automation completed!"
EOF

chmod +x run_stripe_automation.sh
print_success "Run script created (run_stripe_automation.sh)"

# Create quick setup guide
print_status "Creating setup guide..."
cat > STRIPE_SETUP_GUIDE.md << 'EOF'
# 🚀 Stripe Automation Setup Guide

## Quick Start

### 1. Get Your Stripe Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Copy your **Secret Key** (starts with `sk_test_` for testing)
3. Copy your **Publishable Key** (starts with `pk_test_` for testing)

### 2. Configure Environment
```bash
# Copy the template
cp .env.template .env

# Edit with your actual keys
nano .env
```

### 3. Run Automation
```bash
# Make sure you're in the right directory
cd /home/booze/bakery-street-org

# Run the automation
./run_stripe_automation.sh
```

## What This Script Does

✅ **Creates Product**: BlackRock Analyzer
✅ **Creates 4 Pricing Tiers**: Starter ($29), Growth ($79), Professional ($199), Enterprise ($499)
✅ **Sets Metadata**: Product information and features
✅ **Creates Payment Links**: Ready-to-use payment URLs
✅ **Configures Lookup Keys**: Easy management and updates

## Pricing Tiers

| Tier | Price | Features |
|------|-------|----------|
| Starter | $29/month | Basic entity analysis, API access |
| Growth | $79/month | Advanced analysis, priority support |
| Professional | $199/month | Unlimited access, full compliance |
| Enterprise | $499/month | Custom integrations, dedicated support |

## Next Steps

1. **Test Payments**: Use Stripe test cards
2. **Update GitHub**: Add payment links to your profile
3. **Start Marketing**: Begin customer acquisition
4. **Monitor**: Check Stripe dashboard for payments

## Support

- **Stripe Docs**: https://stripe.com/docs
- **Baker Street Project**: sherlock@bakerstreet-project.com
- **GitHub Issues**: [Repository Issues](https://github.com/Bakery-street-projct)

---

**"When you have eliminated the impossible, whatever remains, however improbable, must be the truth."**  
*- Sherlock Holmes*

**And when you've found the truth, automate it!** 💎
EOF

print_success "Setup guide created (STRIPE_SETUP_GUIDE.md)"

echo ""
echo "🎉 Stripe automation setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Get your Stripe API keys from https://dashboard.stripe.com/apikeys"
echo "2. Copy .env.template to .env and fill in your keys"
echo "3. Run: ./run_stripe_automation.sh"
echo ""
echo "📚 Read STRIPE_SETUP_GUIDE.md for detailed instructions"
echo "🔧 Run script: ./run_stripe_automation.sh"
echo ""
echo "Happy automating! 🕵️💰"
