# Self-Hosted AI Starter Kit with FastAPI Integration

A comprehensive Docker-based setup featuring n8n automation, FastAPI webhook integration, and supporting services for AI-powered workflows.

## 📋 Table of Contents

- [Overview](#overview)
- [Services](#services)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [FastAPI Application](#fastapi-application)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)

## 🎯 Overview

This project provides a self-hosted AI automation platform with:
- **n8n** - Workflow automation platform
- **FastAPI** - Python API service for webhook integration
- **PostgreSQL** - Database backend
- **Qdrant** - Vector database for AI embeddings
- **Ollama** - Local LLM hosting (CPU/GPU support)
- **Browserless** - Headless browser automation
- **Portainer** - Container management UI

## 🚀 Services

| Service | Port | Description |
|---------|------|-------------|
| n8n | 5678 | Workflow automation UI |
| FastAPI | 8000 | Webhook caller API |
| PostgreSQL | 5432 | Database (internal) |
| Qdrant | 6333 | Vector database |
| Portainer | 9000 | Container management |
| Browserless | 3002 | Headless Chrome |
| Ollama | 11434 | Local LLM service |

## 📦 Prerequisites

- Docker Desktop installed and running
- At least 4GB RAM available
- 10GB free disk space

**For Mac users:**
```bash
# Install Docker Desktop
brew install --cask docker
```

## ⚡ Quick Start

1. **Clone and navigate to the project:**
```bash
cd self-hosted-ai-starter-kit
```

2. **Configure environment variables:**
```bash
cp .env.example .env  # If .env doesn't exist
```

Edit `.env` and set your n8n webhook URL:
```bash
N8N_WEBHOOK_URL=http://n8n:5678/webhook-test/YOUR-WEBHOOK-ID
```

3. **Start all services:**
```bash
# For CPU-only systems
docker compose --profile cpu up -d --build

# For NVIDIA GPU systems
docker compose --profile gpu-nvidia up -d --build

# For AMD GPU systems
docker compose --profile gpu-amd up -d --build
```

4. **Verify services are running:**
```bash
docker compose ps
```

5. **Access the services:**
- n8n UI: http://localhost:5678
- FastAPI Docs: http://localhost:8000/docs
- Portainer: http://localhost:9000
- Qdrant: http://localhost:6333

## ⚙️ Configuration

### Required Environment Variables

Create or edit `.env` file:

```bash
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=n8n

# n8n Configuration
N8N_ENCRYPTION_KEY=your-super-secret-key
N8N_USER_MANAGEMENT_JWT_SECRET=your-jwt-secret
N8N_WEBHOOK_URL=http://n8n:5678/webhook-test/YOUR-WEBHOOK-ID

# Optional API Keys
OPENAI_API_KEY=sk-...
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### Getting Your n8n Webhook ID

1. Open n8n at http://localhost:5678
2. Create a new workflow or open existing one
3. Add a **Webhook** node
4. Copy the webhook URL (format: `/webhook-test/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)
5. Update `N8N_WEBHOOK_URL` in your `.env` file
6. Restart FastAPI service: `docker compose restart fastapi-app`

## 🔌 FastAPI Application

### Endpoints

#### Health Check
```bash
GET /health
```
Returns the health status of the FastAPI service.

#### Simple Webhook Trigger
```bash
GET /trigger-webhook-simple
```
Triggers your n8n webhook with a default message.

#### Custom Webhook Trigger
```bash
POST /trigger-webhook
Content-Type: application/json

{
  "message": "Your message",
  "data": {
    "key": "value"
  }
}
```
Triggers your n8n webhook with custom payload.

### Interactive API Documentation

Visit http://localhost:8000/docs for interactive Swagger documentation where you can test all endpoints.

## 📝 Usage Examples

### 1. Test Health Endpoint

```bash
curl http://localhost:8000/health
```

**Response:**
```json
{"status": "healthy"}
```

### 2. Trigger Simple Webhook

```bash
curl http://localhost:8000/trigger-webhook-simple
```

**Success Response:**
```json
{
  "status": "success",
  "webhook_url": "http://n8n:5678/webhook-test/...",
  "response_status": 200
}
```

### 3. Trigger with Custom Data

```bash
curl -X POST http://localhost:8000/trigger-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "message": "New order received",
    "data": {
      "order_id": "12345",
      "customer": "John Doe",
      "amount": 99.99
    }
  }'
```

### 4. Using Python Requests

```python
import requests

# Simple trigger
response = requests.get("http://localhost:8000/trigger-webhook-simple")
print(response.json())

# Custom payload
payload = {
    "message": "Processing data",
    "data": {
        "items": [1, 2, 3],
        "status": "pending"
    }
}
response = requests.post(
    "http://localhost:8000/trigger-webhook",
    json=payload
)
print(response.json())
```

### 5. Using JavaScript/Node.js

```javascript
// Using fetch
const response = await fetch('http://localhost:8000/trigger-webhook', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: 'Event triggered',
    data: { event: 'user_signup', user_id: 123 }
  })
});

const result = await response.json();
console.log(result);
```

## 🔧 Troubleshooting

### Docker Not Running
```bash
# Error: Cannot connect to Docker daemon
# Solution: Start Docker Desktop and wait for it to be ready
open -a Docker
```

### Webhook Returns 404
**Issue:** Webhook not registered

**Solution:** 
1. Open n8n at http://localhost:5678
2. Open your workflow
3. Toggle the workflow to **Active** (switch in top-right)

### Webhook Returns 403
**Issue:** Webhook authentication or configuration issue

**Solutions:**
1. Check if workflow is active
2. Verify webhook authentication settings in n8n
3. Try using production webhook instead of test webhook
4. Check n8n logs: `docker compose logs n8n --tail 50`

### Connection Failed Error
**Issue:** Services can't communicate

**Solution:**
```bash
# Restart all services
docker compose down
docker compose up -d --build

# Check network connectivity
docker compose exec fastapi-app ping n8n
```

### Port Already in Use
```bash
# Find process using port 8000
lsof -i :8000

# Kill the process or change FastAPI port in docker-compose.yml
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f fastapi-app
docker compose logs -f n8n

# Last 50 lines
docker compose logs --tail 50 n8n
```

### Reset Everything

```bash
# Stop and remove all containers and volumes
docker compose down -v

# Rebuild and start fresh
docker compose up -d --build
```

## 🏗️ Architecture

```
┌─────────────┐
│   FastAPI   │ :8000
│ (Webhook    │
│  Caller)    │
└──────┬──────┘
       │ HTTP POST
       ▼
┌─────────────┐     ┌──────────────┐
│     n8n     │────▶│  PostgreSQL  │
│ (Workflows) │     │  (Database)  │
└──────┬──────┘     └──────────────┘
       │
       ├──────▶ Browserless (Web Automation)
       ├──────▶ Qdrant (Vector DB)
       └──────▶ Ollama (Local LLM)
```

### Data Flow

1. **External Request** → FastAPI (`/trigger-webhook`)
2. **FastAPI** → n8n Webhook (Internal Docker Network)
3. **n8n Workflow** → Process data, call other services
4. **Response** ← Back to FastAPI → Back to client

### Network

All services run on the `demo` Docker network, allowing them to communicate using service names (e.g., `http://n8n:5678`).

## 📁 Project Structure

```
.
├── docker-compose.yml          # Docker services configuration
├── .env                        # Environment variables (gitignored)
├── fastapi-app/
│   ├── main.py                # FastAPI application
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile            # FastAPI container image
├── n8n/
│   ├── demo-data/            # Sample workflows
│   └── entrypoint.sh         # n8n startup script
└── shared/                   # Shared data between services
```

## 🔐 Security Notes

1. **Change default passwords** in `.env` before production use
2. **Never commit** `.env` file to git
3. **Use HTTPS** in production (add reverse proxy like Nginx)
4. **Secure webhook URLs** with authentication tokens
5. **Limit network exposure** - only expose necessary ports

## 🛠️ Development

### Modifying FastAPI Application

```bash
# Edit the code
vim fastapi-app/main.py

# Rebuild and restart
docker compose up -d --build fastapi-app

# View logs
docker compose logs -f fastapi-app
```

### Adding Dependencies

```bash
# Add to requirements.txt
echo "new-package==1.0.0" >> fastapi-app/requirements.txt

# Rebuild
docker compose up -d --build fastapi-app
```

## 📜 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review Docker logs: `docker compose logs`
- Ensure all services are healthy: `docker compose ps`
