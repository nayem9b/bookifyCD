# PostgreSQL to MongoDB Migration Guide

## Overview

This document outlines the migration from PostgreSQL and pgAdmin to MongoDB and MongoExpress.

## Changes Made

### Removed Components

- ❌ PostgreSQL StatefulSet (postgres:16.10)
- ❌ pgAdmin Deployment (dpage/pgadmin4:8.12)
- ❌ PostgreSQL port 5432 services
- ❌ PostgreSQL secrets and configuration

### Added Components

- ✅ MongoDB StatefulSet (mongo:8.0)
- ✅ MongoExpress Deployment (mongo-express:1.0.2)
- ✅ MongoDB services (headless + cluster IP)
- ✅ MongoExpress service (NodePort 30070)
- ✅ MongoDB and MongoExpress secrets

## Directory Structure Changes

### Before

```
DevSecOps/Database/
├── pg-admin/
│   ├── pg_admin_deployment.yaml
│   ├── pg_admin_secret.yaml
│   └── pg_admin_service.yaml
└── postgres/
    ├── config.md
    ├── postgres_secret.yaml
    ├── postgres_service.yaml
    └── postgres_statefulset.yaml
```

### After

```
DevSecOps/Database/
├── mongodb/
│   ├── config.md (new)
│   ├── mongodb_secret.yaml
│   ├── mongodb_service.yaml
│   └── mongodb_statefulset.yaml
└── mongo-express/
    ├── mongo-express_deployment.yaml (new)
    ├── mongo-express_secret.yaml (new)
    └── mongo-express_service.yaml (new)
```

## Configuration Changes

### Database Connection

#### PostgreSQL (Old)

```
postgres-headless:5432
sheba_db
Username: sheba
```

#### MongoDB (New)

```
mongodb.database.svc.cluster.local:27017
sheba_db
Username: admin
Connection String: mongodb://admin:supersecretpassword@mongodb.database.svc.cluster.local:27017/sheba_db?authSource=admin
```

### Admin Interface

#### pgAdmin (Old)

- Port: 30070
- URL: http://node-ip:30070
- Login with email/password

#### MongoExpress (New)

- Port: 30070
- URL: http://node-ip:30070
- Username: admin
- Password: admin123

## Environment Variables

Update your deployment configuration:

### Old (PostgreSQL)

```
DATABASE_HOST=postgres.bookify.svc.cluster.local
DATABASE_PORT=5432
DATABASE_SSLMODE=require
DB_NAME=sheba_db
DB_USER=sheba
DB_PASSWORD=<password>
```

### New (MongoDB)

```
DATABASE_HOST=mongodb.database.svc.cluster.local
DATABASE_PORT=27017
DATABASE_NAME=sheba_db
MONGODB_USERNAME=admin
MONGODB_PASSWORD=supersecretpassword
# Or use full connection string:
DATABASE_URL=mongodb://admin:supersecretpassword@mongodb.database.svc.cluster.local:27017/sheba_db?authSource=admin
```

## Deployment Steps

### 1. Clean up old PostgreSQL resources (optional)

```bash
kubectl delete namespace database  # This removes everything
# OR selectively delete:
kubectl delete statefulset postgres -n database
kubectl delete deployment pgadmin -n database
kubectl delete service postgres-headless pgadmin-service -n database
kubectl delete secret postgres-secret pgadmin-secret -n database
```

### 2. Create database namespace

```bash
kubectl create namespace database
```

### 3. Deploy MongoDB

```bash
kubectl apply -f DevSecOps/Database/mongodb/
```

### 4. Deploy MongoExpress

```bash
kubectl apply -f DevSecOps/Database/mongo-express/
```

### 5. Verify deployment

```bash
kubectl get pods -n database
kubectl get services -n database
```

### 6. Access MongoExpress

```bash
kubectl port-forward svc/mongo-express-service 8081:8081 -n database
# Or access via NodePort: http://node-ip:30070
```

## Application Code Updates

### Server-side changes needed:

- Update database connection strings in environment variables
- Update database client libraries (Mongoose for MongoDB if using Node.js)
- Update database schemas to MongoDB document format
- Update database queries to MongoDB query syntax
- Update secret references to use `mongodb-secret` instead of `postgres-secret`

### Example updates:

**Before (PostgreSQL):**

```javascript
const connectionString = `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DATABASE_HOST}:${process.env.DATABASE_PORT}/${process.env.DB_NAME}`;
```

**After (MongoDB):**

```javascript
const connectionString = `mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@${process.env.DATABASE_HOST}:${process.env.DATABASE_PORT}/${process.env.DATABASE_NAME}?authSource=admin`;
```

## Storage & Performance Considerations

### MongoDB Storage

- Initial storage request: 5Gi (vs 2Gi for PostgreSQL)
- Adjust in `mongodb_statefulset.yaml` under `volumeClaimTemplates` if needed
- MongoDB can be more storage-intensive for certain use cases

### Resource Limits

- MongoDB requests: 100m CPU, 256Mi memory
- MongoDB limits: 500m CPU, 512Mi memory
- Adjust in `mongodb_statefulset.yaml` under `resources` if needed

## Troubleshooting

### Cannot connect to MongoDB

```bash
# Check if MongoDB pod is running
kubectl get pods -n database

# Check pod logs
kubectl logs -f pod/mongodb-0 -n database

# Test connection
kubectl exec -it pod/mongodb-0 -n database -- mongosh
```

### MongoExpress not accessible

```bash
# Check MongoExpress logs
kubectl logs -f deployment/mongo-express -n database

# Check service
kubectl describe svc mongo-express-service -n database
```

### Database URI issues

Ensure the connection string includes:

- Protocol: `mongodb://`
- Authentication: `username:password@`
- Host and port: `host:27017`
- Database: `/dbname`
- Auth source: `?authSource=admin`

## Rollback (if needed)

To rollback to PostgreSQL:

```bash
# Delete MongoDB resources
kubectl delete -f DevSecOps/Database/mongodb/
kubectl delete -f DevSecOps/Database/mongo-express/

# Redeploy PostgreSQL
kubectl apply -f DevSecOps/Database/postgres/
kubectl apply -f DevSecOps/Database/pg-admin/

# Update application configuration
```

## Notes

- MongoDB uses document-based storage instead of relational tables
- Application queries will need to be adapted for MongoDB syntax
- Connection pooling and indexing strategies may differ
- Backup and recovery procedures will be different
