# ⚙️ Kubernetes Bootstrapping Toolkit

A production-ready automation toolkit to provision, monitor, and manage Kubernetes clusters using **Helm**, **Prometheus**, **Grafana**, and **NGINX Ingress Controller** — with full **GitLab CI/CD** pipeline integration.

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-3.x-blue?logo=helm)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-orange?logo=grafana)
![GitLab CI](https://img.shields.io/badge/GitLab_CI-Automated-FC6D26?logo=gitlab)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Quick Start (Local via Minikube)](#quick-start-local-via-minikube)
- [Project Structure](#project-structure)
- [Helm Charts](#helm-charts)
- [Monitoring & Alerting](#monitoring--alerting)
- [CI/CD Pipeline](#cicd-pipeline)
- [Screenshots](#screenshots)
- [Author](#author)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  GitLab CI/CD Pipeline                   │
│   Build → Test → Deploy → Monitor → Alert               │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                          │
│                                                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  NGINX      │  │  Sample App  │  │  Prometheus   │  │
│  │  Ingress    │  │  (Deployment)│  │  + Grafana    │  │
│  │  Controller │  │              │  │  Stack        │  │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘  │
│         │                │                  │           │
│         └────────────────┴──────────────────┘           │
│                     Cluster Network                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **Kubernetes** | Container orchestration |
| **Helm 3** | Package manager for Kubernetes |
| **Prometheus** | Metrics collection & alerting |
| **Grafana** | Visualization dashboards |
| **NGINX Ingress** | HTTP/HTTPS traffic routing |
| **GitLab CI/CD** | Automated build & deploy pipelines |
| **Docker** | Application containerization |
| **Shell Scripting** | Cluster bootstrap automation |

---

## ✅ Prerequisites

Make sure you have the following installed:

```bash
# Check versions
kubectl version --client
helm version
minikube version
docker --version
```

| Tool | Minimum Version | Install Guide |
|------|----------------|---------------|
| Docker Desktop | 24.x | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Minikube | 1.31+ | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |
| kubectl | 1.28+ | [kubernetes.io/docs](https://kubernetes.io/docs/tasks/tools/) |
| Helm | 3.12+ | [helm.sh/docs](https://helm.sh/docs/intro/install/) |

---

## 🚀 Quick Start (Local via Minikube)

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/k8s-bootstrapping-toolkit.git
cd k8s-bootstrapping-toolkit
```

### 2. Start Minikube

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
minikube addons enable ingress
```

### 3. Run the bootstrap script

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This single script will:
- Add all required Helm repositories
- Create necessary Kubernetes namespaces
- Deploy Prometheus + Grafana monitoring stack
- Deploy NGINX Ingress Controller
- Deploy the sample application
- Output access URLs for all services

### 4. Access the services

```bash
# Get Minikube IP
minikube ip

# Or use port-forward for Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Open in browser
open http://localhost:3000
# Default credentials: admin / admin123
```

---

## 📁 Project Structure

```
k8s-bootstrapping-toolkit/
│
├── scripts/
│   ├── bootstrap.sh          # Full cluster setup in one command
│   ├── teardown.sh           # Clean teardown of all resources
│   └── health-check.sh       # Verify all pods are healthy
│
├── helm/
│   ├── prometheus/
│   │   └── values.yaml       # Custom Prometheus config
│   ├── grafana/
│   │   └── values.yaml       # Custom Grafana config + dashboards
│   └── ingress-nginx/
│       └── values.yaml       # NGINX Ingress config
│
├── app/
│   ├── src/
│   │   └── app.py            # Sample Python Flask app
│   ├── Dockerfile
│   └── k8s/
│       ├── deployment.yaml   # App Deployment manifest
│       ├── service.yaml      # App Service manifest
│       └── ingress.yaml      # Ingress routing rules
│
├── monitoring/
│   ├── dashboards/
│   │   └── cluster-overview.json   # Grafana dashboard JSON
│   └── alerts/
│       └── alert-rules.yaml        # Prometheus alert rules
│
├── .gitlab-ci.yml            # Full CI/CD pipeline definition
├── .gitignore
└── README.md
```

---

## 📦 Helm Charts

### Prometheus Stack

Deploys `kube-prometheus-stack` which includes:
- Prometheus server
- Alertmanager
- Node Exporter
- Kube State Metrics

```bash
# Deploy manually
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f helm/prometheus/values.yaml
```

### Grafana

Pre-configured with:
- Cluster overview dashboard
- Pod resource usage dashboard
- Node metrics dashboard

```bash
# Deploy manually
helm upgrade --install grafana grafana/grafana \
  -n monitoring \
  -f helm/grafana/values.yaml
```

### NGINX Ingress Controller

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f helm/ingress-nginx/values.yaml
```

---

## 📊 Monitoring & Alerting

### Alert Rules Configured

| Alert | Condition | Severity |
|-------|-----------|----------|
| `HighCPUUsage` | CPU > 80% for 5 min | Warning |
| `HighMemoryUsage` | Memory > 85% for 5 min | Warning |
| `PodCrashLooping` | Pod restarting repeatedly | Critical |
| `NodeNotReady` | Node unavailable > 2 min | Critical |
| `DeploymentReplicasMismatch` | Desired != Available | Warning |

### Grafana Dashboards

Pre-imported dashboards:
- **Cluster Overview** — node health, pod count, resource usage
- **Deployment Tracker** — rollout status, replica health

---

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline (`.gitlab-ci.yml`) has 4 stages:

```
build → test → deploy → verify
```

| Stage | Job | Description |
|-------|-----|-------------|
| `build` | `build-image` | Build Docker image, push to registry |
| `test` | `lint-helm` | Lint all Helm charts |
| `test` | `validate-k8s` | Dry-run kubectl apply |
| `deploy` | `deploy-staging` | Helm upgrade to staging namespace |
| `deploy` | `deploy-production` | Helm upgrade to prod (manual trigger) |
| `verify` | `health-check` | Confirm all pods are Running |

---

## 👤 Author

**Vishnu Raj**
- 📧 rajvishnu693@gmail.com
- 💼 [LinkedIn](https://linkedin.com/in/vishnu-raj)
- 🐙 [GitHub](https://github.com/vishnu-raj)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
