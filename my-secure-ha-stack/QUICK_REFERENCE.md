# 🚀 Pure Bliss Quick Reference

## ⚡ Essential Commands

### Start Infrastructure
```bash
cd /opt/my-secure-ha-stack
./orchestrator/agents/start-infrastructure-agent.sh
```

### Check Status
```bash
docker ps --filter "name=purebliss"
```

### Access Site
- **Main:** https://dev.purebliss.app (accept cert warning)
- **Health:** https://dev.purebliss.app/health
- **Keycloak:** http://localhost:8080

## 🔑 Key Credentials
- **PostgreSQL:** `purebliss_admin` / `purebliss_secure_2024!`
- **Keycloak:** `admin` / `admin_password_2024!`

## 🐛 Quick Fixes

### Certificate Warning
Normal for dev environment - click "Advanced" → "Proceed"

### PostgreSQL Reset
```bash
cd /opt/dev-purebliss/services/postgres
docker-compose -f postgres-docker-compose.yml down -v
sudo rm -rf /mnt/raid0/postgres/postgres-data/*
docker-compose -f postgres-docker-compose.yml up -d
```

### Service Restart
```bash
cd /opt/dev-purebliss/services/{service-name}
docker-compose -f {service}-docker-compose.yml restart
```

## 📊 Current Status
- ✅ Vault (18200) - Secrets Management
- ✅ PostgreSQL (5432) - Database  
- ✅ Redis (6379) - Cache
- ✅ Nginx (80/443) - Web Server
- ✅ LetsEncrypt - SSL Management
- ✅ Keycloak (8080) - Authentication

**Ready for 107,500 customers/year!** 🎯
