# AWS Deployment Guide

## Prerequisites

- AWS EC2 instance running (Ubuntu 22.04 LTS recommended)
- Docker and Docker Compose installed on the instance
- Public IP associated with your instance
- Port 80 and 443 open in AWS Security Group
- Email address for Let's Encrypt certificate renewal notifications

## Step-by-Step Setup

### 1. Update .env File

Edit `.env` file and update with your AWS details:

```env
# Your AWS instance public IP
APP_PUBLIC_IP=3.95.22.151

# Database Configuration (keep as is or change if needed)
DB_NAME=school
DB_USER=student
DB_PASSWORD=student123

# Frontend API URL - must match your public IP
VITE_API_URL=https://3.95.22.151/api

# Your email for Let's Encrypt renewal notifications
CERTBOT_EMAIL=your-email@example.com
```

### 2. Configure AWS Security Group

Make sure these inbound rules are open:

| Protocol | Port | Source |
|----------|------|--------|
| TCP | 80 | 0.0.0.0/0 (Anywhere) |
| TCP | 443 | 0.0.0.0/0 (Anywhere) |
| TCP | 5432 | Your IP (PostgreSQL - optional) |

### 3. Setup SSL Certificate (IMPORTANT - Do This First!)

Run the SSL setup script to get Let's Encrypt certificate:

```bash
chmod +x setup-ssl.sh
./setup-ssl.sh
```

This will:
- Create necessary directories
- Start nginx temporarily
- Request SSL certificate from Let's Encrypt
- Validate your domain/IP is publicly accessible

**Note:** If it fails, check:
- Port 80 is accessible from the internet
- APP_PUBLIC_IP is correct
- CERTBOT_EMAIL is valid

### 4. Start All Services

Once SSL is setup, start the complete application:

```bash
docker-compose up -d
```

Verify services are running:

```bash
docker-compose ps
```

### 5. Access Your Application

- **Frontend:** `https://3.95.22.151`
- **API:** `https://3.95.22.151/api`
- **Database (internal only):** `postgres:5432`

## Architecture

```
┌─────────────────────────────────────────┐
│      AWS EC2 Instance (Public)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐   │
│  │   Nginx Reverse Proxy (Port 443) │   │
│  │   - HTTPS with Let's Encrypt     │   │
│  │   - Routes /api → Spring Boot    │   │
│  │   - Routes / → React Frontend    │   │
│  └──────────────────────────────────┘   │
│           │                    │         │
│           ├────────────┬───────┘         │
│           │            │                 │
│      ┌────▼──┐     ┌───▼──────┐        │
│      │Spring │     │  React   │        │
│      │Boot   │     │Frontend  │        │
│      │API    │     │(Nginx)   │        │
│      │:8080  │     │:5173     │        │
│      └────┬──┘     └──────────┘        │
│           │                             │
│      ┌────▼──────────┐                 │
│      │  PostgreSQL   │                 │
│      │  Database     │                 │
│      │  :5432        │                 │
│      └───────────────┘                 │
│                                         │
└─────────────────────────────────────────┘
```

## Useful Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f nginx
docker-compose logs -f api
docker-compose logs -f frontend

# Certbot (SSL renewal)
docker-compose logs -f certbot
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart api
docker-compose restart nginx
```

### SSL Certificate Info

```bash
# Check certificate expiry
docker run --rm -v $(pwd)/certbot/conf:/etc/letsencrypt \
  certbot/certbot certificates

# Manual renewal
docker-compose exec certbot \
  certbot renew --webroot -w /var/www/certbot
```

### Database Access

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U student -d school

# Useful commands:
# \dt          - List tables
# \d students  - Describe table
# SELECT * FROM students; - Query data
```

## Troubleshooting

### Application not accessible
- Check Security Group allows port 80 and 443
- Verify APP_PUBLIC_IP is correct
- Run: `docker-compose logs nginx`

### SSL Certificate fails
- Ensure port 80 is accessible from internet
- Check CERTBOT_EMAIL is correct
- Verify APP_PUBLIC_IP resolves publicly
- Run: `docker-compose logs certbot`

### API not responding
- Check Spring Boot is running: `docker-compose ps`
- Check database connection: `docker-compose logs api`
- Verify CORS configuration

### Database connection issues
- Verify postgres service is healthy: `docker-compose ps`
- Check credentials in .env match application.yml
- Run: `docker-compose logs postgres`

## Maintenance

### Automatic Certificate Renewal

Certbot service runs automatically and renews certificates before expiry (every 12 hours).

### Backup Database

```bash
docker-compose exec postgres pg_dump -U student school > backup.sql
```

### Restore Database

```bash
docker-compose exec -T postgres psql -U student school < backup.sql
```

## Security Best Practices

1. **Change Database Credentials** - Don't use default in production
2. **Use Strong Passwords** - Update in .env file
3. **Restrict Database Access** - Only expose to internal services
4. **Enable Firewall Rules** - Limit access by IP when possible
5. **Regular Backups** - Backup database regularly
6. **Monitor Logs** - Regularly check for errors and suspicious activity
7. **Keep Docker Updated** - Regularly update Docker images

## Performance Tips

1. **Use EBS Volume** - Store database data on EBS for persistence
2. **Enable Caching** - Configure Redis for session/API caching
3. **CDN** - Use CloudFront for static assets
4. **Load Balancing** - Scale horizontally with multiple instances
5. **Monitoring** - Use CloudWatch for monitoring

## Next Steps

1. ✓ Setup SSL with Let's Encrypt
2. ✓ Start all services
3. ✓ Test the application
4. ✓ Configure auto-backups
5. ✓ Setup monitoring
