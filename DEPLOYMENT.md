# Deployment Guide - EC2 with GitHub Actions

This guide explains how to set up CI/CD using GitHub Actions to deploy this Next.js application to an EC2 instance.

## Prerequisites

1. An EC2 instance running Ubuntu (or similar Linux distribution)
2. Docker and Docker Compose installed on the EC2 instance
3. SSH access to your EC2 instance
4. A GitHub repository for your project

## Step 1: Prepare Your EC2 Instance

### 1.1 Install Docker and Docker Compose

SSH into your EC2 instance and run:

```bash
# Update system packages
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to the docker group (replace 'ubuntu' with your username)
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and log back in for group changes to take effect
```

### 1.2 Create App Directory

```bash
mkdir -p ~/app
cd ~/app
```

### 1.3 Set Up SSH Key for GitHub Actions

Generate an SSH key pair (or use an existing one):

```bash
# On your local machine or EC2 instance
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions_deploy
```

Add the public key to your EC2 instance's `~/.ssh/authorized_keys`:

```bash
# On EC2 instance
cat ~/.ssh/github_actions_deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Important:** Keep the private key (`github_actions_deploy`) secure - you'll add it to GitHub Secrets.

### 1.4 Configure Security Group

Ensure your EC2 security group allows:
- SSH (port 22) from GitHub Actions IPs or your IP
- HTTP (port 80) and HTTPS (port 443) from anywhere (0.0.0.0/0)
- Port 3000 from anywhere if accessing directly (or use a reverse proxy)

## Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

### Required Secrets:

1. **`EC2_HOST`** - Your EC2 instance public IP or domain name
   - Example: `ec2-12-34-56-78.compute-1.amazonaws.com` or `54.123.45.67`

2. **`EC2_USER`** - SSH username for your EC2 instance
   - Example: `ubuntu` (for Ubuntu AMI) or `ec2-user` (for Amazon Linux)

3. **`EC2_SSH_KEY`** - Private SSH key content
   - Copy the entire content of `~/.ssh/github_actions_deploy` (private key)
   - Include the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines

4. **`EC2_PORT`** - SSH port (optional, defaults to 22)
   - Example: `22`

### Optional Secrets (if using AWS services):

5. **`AWS_ACCESS_KEY_ID`** - AWS access key (if needed for other AWS services)

6. **`AWS_SECRET_ACCESS_KEY`** - AWS secret access key

7. **`AWS_REGION`** - AWS region
   - Example: `us-east-1`

## Step 3: Configure Docker Compose (if needed)

Ensure your `docker-compose.yml` is configured correctly for production. You may want to add:

- Environment variables
- Volume mounts for persistent data
- Health checks
- Restart policies

Example production `docker-compose.yml`:

```yaml
version: '3.8'

services:
  nextjs-app:
    build:
      context: .
      dockerfile: dockerfile
    container_name: react-portfolio
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Step 4: Set Up Reverse Proxy (Recommended)

For production, use Nginx as a reverse proxy:

### Install Nginx on EC2:

```bash
sudo apt-get install nginx -y
```

### Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/portfolio
```

Add:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Set up SSL with Let's Encrypt:

```bash
sudo apt-get install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## Step 5: Test the Deployment

1. Push a change to the `main` branch
2. Go to your GitHub repository → Actions tab
3. Watch the workflow run
4. Once complete, visit your EC2 instance's public IP or domain

## Troubleshooting

### SSH Connection Issues

- Verify your security group allows SSH from GitHub Actions IPs
- Check that the SSH key is correctly formatted in GitHub Secrets
- Ensure the EC2_USER matches your instance's default user

### Docker Issues

- Verify Docker and Docker Compose are installed: `docker --version` and `docker-compose --version`
- Check Docker daemon is running: `sudo systemctl status docker`
- View logs: `docker-compose logs -f`

### Application Not Accessible

- Check if the container is running: `docker-compose ps`
- Verify port 3000 is accessible: `curl http://localhost:3000`
- Check security group rules for ports 80, 443, and 3000
- Review application logs: `docker-compose logs nextjs-app`

### Build Failures

- Check GitHub Actions logs for specific error messages
- Verify all dependencies are in `package.json`
- Ensure `next.config.js` has `output: 'standalone'` for Docker deployment

## Manual Deployment

If you need to deploy manually:

```bash
# SSH into your EC2 instance
ssh -i ~/.ssh/your-key.pem ubuntu@your-ec2-ip

# Navigate to app directory
cd ~/app

# Run the deployment script
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Or manually:

```bash
cd ~/app
docker-compose down
docker-compose up -d --build
docker image prune -f
```

## Monitoring

Consider setting up:

- CloudWatch for EC2 monitoring
- Application monitoring (e.g., Sentry, LogRocket)
- Uptime monitoring (e.g., UptimeRobot, Pingdom)

## Security Best Practices

1. **Never commit secrets** - Always use GitHub Secrets
2. **Use IAM roles** - Prefer IAM roles over access keys when possible
3. **Restrict SSH access** - Limit SSH access to specific IPs in security groups
4. **Keep dependencies updated** - Regularly update Docker images and system packages
5. **Use HTTPS** - Always use SSL/TLS in production
6. **Regular backups** - Set up automated backups for your data

## Next Steps

- Set up automated backups
- Configure monitoring and alerting
- Set up staging environment
- Implement blue-green deployments
- Add database migrations if needed

