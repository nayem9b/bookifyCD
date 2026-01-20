# MongoDB Configuration

## Overview

This deployment uses MongoDB 8.0 as the primary database with MongoExpress as the web-based administration interface.

## Components

### MongoDB StatefulSet

- **Image**: mongo:8.0
- **Port**: 27017
- **Storage**: 5Gi PVC
- **Username**: admin
- **Database**: sheba_db

### MongoExpress Deployment

- **Image**: mongo-express:1.0.2
- **Port**: 8081
- **Access**: NodePort 30070
- **Web UI**: http://localhost:30070

## Connection String

For applications, use the following connection string:

```
mongodb://admin:supersecretpassword@mongodb.database.svc.cluster.local:27017/sheba_db?authSource=admin
```

## Credentials

- **MongoDB Admin Username**: admin
- **MongoDB Admin Password**: supersecretpassword (stored in mongodb-secret)
- **MongoExpress Web UI Username**: admin
- **MongoExpress Web UI Password**: admin123

## Deployment

Apply the manifests in this order:

1. Create namespace (if not exists): `kubectl create namespace database`
2. Apply secrets: `kubectl apply -f mongodb_secret.yaml`
3. Apply StatefulSet: `kubectl apply -f mongodb_statefulset.yaml`
4. Apply services: `kubectl apply -f mongodb_service.yaml`
5. Apply MongoExpress secret: `kubectl apply -f mongo-express_secret.yaml`
6. Apply MongoExpress deployment: `kubectl apply -f mongo-express_deployment.yaml`
7. Apply MongoExpress service: `kubectl apply -f mongo-express_service.yaml`

Or apply all at once:

```bash
kubectl apply -f .
```

## Accessing MongoExpress

1. Get the service URL: `kubectl get svc mongo-express-service -n database`
2. Access via NodePort: `http://<node-ip>:30070`
3. Login credentials:
   - Username: admin
   - Password: admin123
