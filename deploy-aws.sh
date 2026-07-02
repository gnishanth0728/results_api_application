#!/bin/bash

# AWS Deployment Script
# Run this on your AWS EC2 instance

set -e

echo "=== AWS Deployment Script ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Stop and remove old containers/volumes
echo -e "${YELLOW}Step 1: Cleaning up old containers and volumes...${NC}"
sudo docker compose down -v
echo -e "${GREEN}✓ Cleaned${NC}\n"

# Step 2: Build images
echo -e "${YELLOW}Step 2: Building Docker images...${NC}"
sudo docker compose build
echo -e "${GREEN}✓ Build complete${NC}\n"

# Step 3: Start all services
echo -e "${YELLOW}Step 3: Starting services...${NC}"
sudo docker compose up -d
echo -e "${GREEN}✓ Services started${NC}\n"

# Step 4: Wait for database to be ready
echo -e "${YELLOW}Step 4: Waiting for database to initialize...${NC}"
sleep 15
echo -e "${GREEN}✓ Database ready${NC}\n"

# Step 5: Verify services
echo -e "${YELLOW}Step 5: Verifying services...${NC}"
echo ""
sudo docker compose ps
echo ""

# Step 6: Show access information
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${YELLOW}Access your application at:${NC}"
echo "  Frontend:  http://3.95.22.151"
echo "  API:       http://3.95.22.151/api"
echo ""

echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs:      sudo docker-compose logs -f"
echo "  View API logs:  sudo docker-compose logs -f api"
echo "  Check status:   sudo docker-compose ps"
echo "  Stop all:       sudo docker-compose down"
echo ""
