#!/bin/bash
set -e

# Deployment script for Hermes backend to EC2
# Usage: ./deploy-backend.sh <instance-ip> <domain-name>
# Example: ./deploy-backend.sh 54.123.45.67 api.yourdomain.com

if [ $# -lt 2 ]; then
    echo "Usage: $0 <instance-ip> <domain-name>"
    echo "Example: $0 54.123.45.67 api.yourdomain.com"
    exit 1
fi

INSTANCE_IP=$1
DOMAIN_NAME=$2
BACKEND_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "🚀 Deploying Hermes backend to $INSTANCE_IP..."

# Build Docker image locally
echo "📦 Building Docker image..."
cd "$BACKEND_DIR/backend"
docker build -t hermes-backend:latest .

# Save image to tar file
echo "💾 Saving Docker image..."
docker save hermes-backend:latest -o /tmp/hermes-backend.tar

# Copy image to EC2
echo "📤 Copying image to EC2..."
scp /tmp/hermes-backend.tar ubuntu@$INSTANCE_IP:/tmp/

# Copy environment file template
echo "📋 Copying environment template..."
scp "$BACKEND_DIR/backend/env.example" ubuntu@$INSTANCE_IP:/opt/hermes-backend/.env.template

# SSH and deploy
echo "🔧 Setting up on EC2..."
ssh ubuntu@$INSTANCE_IP << EOF
set -e

# Load Docker image
echo "Loading Docker image..."
sudo docker load -i /tmp/hermes-backend.tar
rm /tmp/hermes-backend.tar

# Stop existing container if running
sudo docker stop hermes-backend 2>/dev/null || true
sudo docker rm hermes-backend 2>/dev/null || true

# Create .env file if it doesn't exist
if [ ! -f /opt/hermes-backend/.env ]; then
    echo "⚠️  Creating .env file from template..."
    cp /opt/hermes-backend/.env.template /opt/hermes-backend/.env
    echo "⚠️  Please edit /opt/hermes-backend/.env with your LiveKit credentials!"
    echo "⚠️  Run: sudo nano /opt/hermes-backend/.env"
fi

# Run backend container
echo "Starting backend container..."
sudo docker run -d \\
    --name hermes-backend \\
    --restart unless-stopped \\
    -p 3001:3001 \\
    --env-file /opt/hermes-backend/.env \\
    hermes-backend:latest

echo "✅ Backend container started!"
echo "Check logs with: sudo docker logs -f hermes-backend"
EOF

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. SSH to instance: ssh ubuntu@$INSTANCE_IP"
echo "2. Edit environment file: sudo nano /opt/hermes-backend/.env"
echo "3. Restart container: sudo docker restart hermes-backend"
echo "4. Check logs: sudo docker logs -f hermes-backend"
echo "5. Set up SSL: sudo certbot --nginx -d $DOMAIN_NAME"
