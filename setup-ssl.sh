#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== SSL Certificate Setup for Let's Encrypt ===${NC}\n"

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo -e "${GREEN}✓ Environment variables loaded${NC}"
else
    echo -e "${RED}✗ .env file not found. Please create it first.${NC}"
    exit 1
fi

# Check if APP_PUBLIC_IP is set
if [ -z "$APP_PUBLIC_IP" ]; then
    echo -e "${RED}✗ APP_PUBLIC_IP is not set in .env${NC}"
    exit 1
fi

# Check if CERTBOT_EMAIL is set
if [ -z "$CERTBOT_EMAIL" ]; then
    echo -e "${RED}✗ CERTBOT_EMAIL is not set in .env${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuration:${NC}"
echo "  Public IP: $APP_PUBLIC_IP"
echo "  Email: $CERTBOT_EMAIL"
echo ""

# Create certbot directories if they don't exist
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

echo -e "${YELLOW}Starting Docker services...${NC}\n"

# Start only nginx for certbot to work
docker-compose up -d nginx

# Wait for nginx to be ready
echo -e "${YELLOW}Waiting for nginx to be ready...${NC}"
sleep 5

# Request certificate
echo -e "${YELLOW}Requesting SSL certificate...${NC}\n"

docker run --rm --name certbot \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  -p 80:80 \
  certbot/certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --agree-tos \
    --no-eff-email \
    -m "$CERTBOT_EMAIL" \
    -d "$APP_PUBLIC_IP"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate successfully created!${NC}\n"
    echo -e "${YELLOW}Certificate details:${NC}"
    echo "  Path: ./certbot/conf/live/$APP_PUBLIC_IP/"
    echo ""
    echo -e "${GREEN}You can now start the full application with:${NC}"
    echo "  docker-compose up -d"
else
    echo -e "${RED}✗ Failed to create SSL certificate${NC}"
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "  1. Make sure port 80 is accessible from the internet"
    echo "  2. Check that your APP_PUBLIC_IP is correct and publicly resolves"
    echo "  3. Check that CERTBOT_EMAIL is a valid email"
    exit 1
fi
