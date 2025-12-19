# Domain Name Setup Guide

## What is a Domain Name?

A domain name is a human-readable address like `api.yourdomain.com` instead of an IP address like `15.188.222.229`.

**Why use a domain?**
- Easier to remember
- Required for SSL certificates (HTTPS)
- Can change IP addresses without updating clients
- More professional

## Do You Need a Domain?

**Short answer: Not immediately!** 

You can use the IP address (`15.188.222.229`) for now. The Terraform configuration will automatically use the IP address if you don't provide a domain.

## How to Get a Domain (When Ready)

### Option 1: Buy a Domain

Popular registrars:
- **Namecheap**: ~$10-15/year for `.com`
- **Google Domains**: ~$12/year for `.com`
- **Cloudflare Registrar**: At-cost pricing (~$8-10/year)
- **AWS Route 53**: ~$12/year for `.com`

### Option 2: Use a Free Subdomain

- **Freenom**: Free `.tk`, `.ml`, `.ga` domains (not recommended for production)
- **DuckDNS**: Free subdomains like `yourname.duckdns.org`

## How to Configure Domain in Terraform

### Step 1: Buy/Register Domain

Purchase from any registrar (e.g., Namecheap, Google Domains).

### Step 2: Point Domain to Your EC2 IP

**If using Route 53 (AWS):**
```bash
# Create hosted zone
aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)

# Create A record pointing to EC2 IP
aws route53 change-resource-record-sets --hosted-zone-id <zone-id> --change-batch '{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "api.yourdomain.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "15.188.222.229"}]
    }
  }]
}'
```

**If using other DNS provider:**
- Go to your domain registrar's DNS settings
- Create an A record: `api` → `15.188.222.229`
- Wait 5-60 minutes for DNS to propagate

### Step 3: Update Terraform

```bash
terraform apply -var="domain_name=api.yourdomain.com"
```

Or create `terraform.tfvars`:
```hcl
domain_name = "api.yourdomain.com"
```

### Step 4: Set Up SSL Certificate

Once domain is configured:
```bash
ssh -i /tmp/hermes-backend-key.pem ubuntu@15.188.222.229
sudo certbot --nginx -d api.yourdomain.com
```

## Current Setup (Using IP Address)

Right now, Terraform is configured to:
- Use IP address `15.188.222.229` as the server name
- Work without a domain
- Allow you to add a domain later

**Your backend will be accessible at:**
- `http://15.188.222.229` (HTTP)
- `https://15.188.222.229` (HTTPS - after SSL setup)

## When to Add a Domain

Add a domain when:
- ✅ You want HTTPS/SSL certificates (requires domain)
- ✅ You're ready for production use
- ✅ You want a professional URL

You can continue using the IP address for development/testing.
