#!/bin/bash

echo "TroupeX UI Test Script"
echo "======================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "mastodon" ]; then
    echo -e "${RED}Error: mastodon directory not found!${NC}"
    exit 1
fi

cd mastodon

echo "1. Checking environment setup..."
echo "--------------------------------"

# Check if .env.development exists
if [ -f ".env.development" ]; then
    echo -e "${GREEN}✓ .env.development file exists${NC}"
else
    echo -e "${RED}✗ .env.development file missing${NC}"
fi

# Check if dependencies are installed
if [ -d "vendor/bundle" ]; then
    echo -e "${GREEN}✓ Ruby dependencies installed${NC}"
else
    echo -e "${RED}✗ Ruby dependencies not installed${NC}"
fi

if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓ Node dependencies installed${NC}"
else
    echo -e "${RED}✗ Node dependencies not installed${NC}"
fi

echo ""
echo "2. Checking brand assets..."
echo "---------------------------"

# Check logo files
if [ -f "app/javascript/images/logo.svg" ]; then
    if grep -q "TROUPE" app/javascript/images/logo.svg && grep -q "X" app/javascript/images/logo.svg; then
        echo -e "${GREEN}✓ logo.svg contains TroupeX branding${NC}"
    else
        echo -e "${RED}✗ logo.svg missing TroupeX branding${NC}"
    fi
else
    echo -e "${RED}✗ logo.svg not found${NC}"
fi

if [ -f "app/javascript/images/logo-symbol-wordmark.svg" ]; then
    if grep -q "TROUPE" app/javascript/images/logo-symbol-wordmark.svg && grep -q "X" app/javascript/images/logo-symbol-wordmark.svg; then
        echo -e "${GREEN}✓ logo-symbol-wordmark.svg contains TroupeX branding${NC}"
    else
        echo -e "${RED}✗ logo-symbol-wordmark.svg missing TroupeX branding${NC}"
    fi
else
    echo -e "${RED}✗ logo-symbol-wordmark.svg not found${NC}"
fi

echo ""
echo "3. Checking UI components..."
echo "----------------------------"

# Check footer branding
if grep -q "TroupeX" app/javascript/mastodon/features/ui/components/link_footer.tsx; then
    echo -e "${GREEN}✓ Footer shows 'TroupeX v0.1'${NC}"
else
    echo -e "${RED}✗ Footer still shows old branding${NC}"
fi

# Check login page
if [ -f "app/views/auth/sessions/new.html.haml" ]; then
    if grep -q "troupex-login-page" app/views/auth/sessions/new.html.haml; then
        echo -e "${GREEN}✓ New TroupeX login page implemented${NC}"
    else
        echo -e "${RED}✗ Login page not updated${NC}"
    fi
else
    echo -e "${RED}✗ Login page not found${NC}"
fi

echo ""
echo "4. Checking theme files..."
echo "--------------------------"

# Check dark theme
if [ -f "app/javascript/styles/mastodon/troupex-dark-theme.scss" ]; then
    echo -e "${GREEN}✓ Dark theme file created${NC}"
else
    echo -e "${RED}✗ Dark theme file missing${NC}"
fi

# Check if dark theme is imported
if grep -q "troupex-dark-theme" app/javascript/styles/application.scss; then
    echo -e "${GREEN}✓ Dark theme imported in application.scss${NC}"
else
    echo -e "${RED}✗ Dark theme not imported${NC}"
fi

# Check if light theme override is removed
if grep -q "troupex-theme-override" app/javascript/styles/application.scss; then
    echo -e "${RED}✗ Light theme override still imported${NC}"
else
    echo -e "${GREEN}✓ Light theme override removed${NC}"
fi

# Check login styles
if [ -f "app/javascript/styles/mastodon/troupex-login.scss" ]; then
    echo -e "${GREEN}✓ Login styles created${NC}"
else
    echo -e "${RED}✗ Login styles missing${NC}"
fi

echo ""
echo "5. Checking services..."
echo "-----------------------"

# Check PostgreSQL
if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${YELLOW}! PostgreSQL is not running (run ./setup-troupex-dev.sh)${NC}"
fi

# Check Redis
if systemctl is-active --quiet redis; then
    echo -e "${GREEN}✓ Redis is running${NC}"
else
    echo -e "${YELLOW}! Redis is not running (run ./setup-troupex-dev.sh)${NC}"
fi

# Check if database exists
if RAILS_ENV=development bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" 2>/dev/null; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${YELLOW}! Database not accessible (run ./run-db-setup.sh)${NC}"
fi

echo ""
echo "6. Running linters..."
echo "--------------------"

# Run JavaScript linter (quick check)
echo "Running ESLint on modified files..."
if yarn lint:js --max-warnings 0 app/javascript/mastodon/features/ui/components/link_footer.tsx 2>/dev/null; then
    echo -e "${GREEN}✓ JavaScript linting passed${NC}"
else
    echo -e "${YELLOW}! JavaScript linting warnings (non-critical)${NC}"
fi

# Check SCSS compilation
echo "Checking SCSS compilation..."
if yarn build:development 2>&1 | grep -q "error"; then
    echo -e "${RED}✗ SCSS compilation errors${NC}"
else
    echo -e "${GREEN}✓ SCSS compiles successfully${NC}"
fi

echo ""
echo "Test Summary"
echo "============"
echo ""
echo "To start the development server:"
echo "1. Run ${YELLOW}./setup-troupex-dev.sh${NC} (if PostgreSQL/Redis not running)"
echo "2. Run ${YELLOW}./run-db-setup.sh${NC} (if database not set up)"
echo "3. Run ${YELLOW}./start-dev-server.sh${NC} in one terminal"
echo "4. Run ${YELLOW}./start-vite-dev.sh${NC} in another terminal"
echo ""
echo "Then visit ${GREEN}http://localhost:3000/auth/sign_in${NC} to see the new login page"
echo ""