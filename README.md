# 🚀 High-Traffic WordPress Infrastructure on AWS
### hosting-101.com | Scalable & Secure Architecture for Tens of Thousands of Concurrent Users

---

## 📋 Table of Contents

- [Project Scenario](#-project-scenario)
- [Architecture Overview](#-architecture-overview)
- [Infrastructure Components](#-infrastructure-components)
- [Network Design (VPC & Subnets)](#-network-design-vpc--subnets)
- [Traffic Flow](#-traffic-flow)
- [Security Strategy](#-security-strategy)
- [Storage Architecture](#-storage-architecture)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Cost Estimation](#-cost-estimation)
- [Project Phases](#-project-phases)
- [Alternative Approaches](#-alternative-approaches)
- [Tech Stack](#-tech-stack)

---

## 📌 Project Scenario

**hosting-101.com** is a high-traffic internet portal running on WordPress infrastructure. The site faces the following real-world challenges:

| Challenge | Detail |
|-----------|--------|
| 📈 Traffic Spikes | Traffic surges to **tens of thousands of concurrent users** during promotional periods |
| 🔍 SEO Critical | Google SEO score and **page loading time** are business-critical metrics |
| 🛡️  Attacks | The site constantly receives simultaneous attacks from multiple countries and IP addresses |
| 💾 Daily Backups | Regulatory and operational requirement for daily automated backups |
| 📦 Site Size | 30 GB total WordPress installation |

**Technical Stack:**
- **CMS:** WordPress
- **PHP Version:** 8.1
- **Database:** MariaDB
- **Caching:** Memcached

The goal of this project was to design and provision a **production-ready, auto-scaling AWS architecture** that meets all of these requirements while remaining cost-effective.

---

## 🏗️ Architecture Overview

![Architecture Diagram](<img width="1307" height="924" alt="image" src="https://github.com/user-attachments/assets/94c6ca8a-5483-4298-8e71-096b58807071" />
)

The architecture is built on a **multi-AZ, containerized, serverless compute model** using AWS Fargate inside a custom VPC across two Availability Zones.

```

```

---

## 🧩 Infrastructure Components

### Compute
| Service | Role | Configuration |
|---------|------|---------------|
| **AWS Fargate** | Serverless container compute | ARM architecture, 2 GB RAM, 6 tasks/month avg, 730 hrs |
| **Amazon ECR** | Container image registry | 10 GB storage |
| **ALB** | Application Load Balancer | 1 ALB, distributes traffic across AZs |

### Database
| Service | Role | Configuration |
|---------|------|---------------|
| **Amazon RDS (MariaDB)** | Primary database | `db.t4g.medium`, Multi-AZ, 20 GB GP3 SSD, On-Demand |
| **ElastiCache (Memcached)** | Database query caching | `cache.t4g.small`, 2 nodes (1 per AZ) |


### Storage
| Service | Role | Configuration |
|---------|------|---------------|
| **Amazon EFS** | Shared WordPress files (wp-content) | 2 GB provisioned, mounted in both AZs |
| **Amazon S3** | Static assets, media uploads, CloudFront origin | 50 GB Standard storage |
| **AWS Backup** | Daily automated backups | 30-day warm retention, 50 GB backup storage |

### CDN & Security
| Service | Role | Configuration |
|---------|------|---------------|
| **Amazon CloudFront** | Global CDN, edge caching | 0.5 TB/month transfer, 1M+ HTTPS requests/month |
| **AWS WAF** | Web Application Firewall | 1 Web ACL, 5 custom rules |
| **Amazon Route 53** | DNS management | Latency-based routing |
| **VPC NAT Gateway** | Outbound internet for private subnets | 2 NAT GWs (one per AZ), 3 public IPs |

### Monitoring & CI/CD
| Service | Role |
|---------|------|
| **Amazon CloudWatch** | Metrics, alarms, dashboards, log aggregation |
| **AWS CodePipeline** | CI/CD orchestration |
| **AWS CodeBuild** | Docker image build |
| **AWS CodeDeploy** | Blue/green deployment to ECS |

---

## 🌐 Network Design (VPC & Subnets)

The VPC uses a **3-tier subnet model** replicated across 2 Availability Zones for high availability.

### CIDR Block Allocation

```
VPC: 10.0.0.0/16  (65,536 IPs)
│
├── PUBLIC SUBNETS (Internet-facing, NAT Gateways)
│   ├── public-subnet-1a:  10.0.1.0/24   (AZ: eu-central-1a)
│   └── public-subnet-1b:  10.0.2.0/24   (AZ: eu-central-1b)
│
├── APP PRIVATE SUBNETS (ECS Fargate Tasks)
│   ├── app-private-subnet-1a:  10.0.10.0/24  (AZ: eu-central-1a)
│   └── app-private-subnet-1b:  10.0.11.0/24  (AZ: eu-central-1b)
│
└── DATA PRIVATE SUBNETS (RDS, ElastiCache, EFS)
    ├── data-private-subnet-1a:  10.0.20.0/24  (AZ: eu-central-1a)
    └── data-private-subnet-1b:  10.0.21.0/24  (AZ: eu-central-1b)
```

### Why This Design?
- **Public subnets** only contain NAT Gateways — no application servers are internet-reachable.
- **App subnets** are isolated — ECS tasks can only be reached via ALB, outbound via NAT.
- **Data subnets** are fully private — no route to the internet, only accept connections from App subnets.
- Multi-AZ deployment ensures zero downtime if one availability zone fails.

---

## 🔄 Traffic Flow

```
1. USER REQUEST
   └─► Route 53 (DNS Resolution)
         └─► CloudFront Edge Location
               ├── [CACHE HIT]  → Return cached response (< 50ms globally)
               └── [CACHE MISS] → Forward to Origin
                     └─► WAF (Inspect request, block malicious traffic)
                           └─► Internet Gateway
                                 └─► ALB (Health-check aware routing)
                                       ├── Route to AZ-1a: ECS Fargate Task
                                       └── Route to AZ-1b: ECS Fargate Task

2. APPLICATION LAYER (ECS Fargate Task)
   ├─► ElastiCache Memcached (Check object cache)
   │     ├── [CACHE HIT]  → Return cached data
   │     └── [CACHE MISS] → Query RDS
   ├─► RDS MariaDB (Master for writes, reads via endpoint)
   ├─► EFS Mount (WordPress core files, wp-content/uploads)
   └─► S3 (Static media via WP Offload Media or similar plugin)

3. RESPONSE
   └─► CloudFront caches the response at edge
         └─► Delivered to user with low latency
```

---

## 🛡️ Security Strategy

### Multi-Layer Defense

```
Layer 1: CloudFront + WAF
  - DDoS protection (AWS Shield Standard included)
  - WAF rules block common WordPress attacks (SQLi, XSS, bad bots)
  - Geographic blocking capability for known attack origins
  - Rate limiting per IP

Layer 2: VPC Network Isolation
  - Application servers in private subnets (no public IPs)
  - Security groups: ALB → ECS → RDS (least-privilege rules)
  - NACLs for subnet-level traffic control

Layer 3: Container Security
  - ECR image scanning on push
  - IAM Task Roles (least-privilege per container)
  - No long-lived credentials inside containers

Layer 4: Data Security
  - RDS encryption at rest (AES-256)
  - EFS encryption at rest and in transit
  - S3 server-side encryption (SSE-S3)
```

---

## 💾 Storage Architecture

The project uses a **hybrid storage approach** optimized for WordPress:

```
WordPress File Types & Storage Mapping:
─────────────────────────────────────────────────────
wp-core / wp-admin / wp-includes  →  EFS (shared, read-only for app)
wp-content/themes, plugins        →  EFS (shared across all containers)
wp-content/uploads (media)        →  S3  (offloaded, served via CloudFront)
wp-config.php / secrets           →  AWS Secrets Manager / SSM
Database                          →  RDS MariaDB (Multi-AZ)
Session cache / object cache      →  ElastiCache Memcached
Daily snapshots                   →  AWS Backup → S3 Glacier
─────────────────────────────────────────────────────
```

**Why EFS for WordPress files?**
Multiple Fargate tasks running in different AZs need access to the same `wp-content` directory. EFS provides a POSIX-compliant shared filesystem mounted via NFS, allowing all containers to read/write the same files consistently.

---

## 🔁 CI/CD Pipeline

```
Developer Push (GitHub/CodeCommit)
         ↓
   AWS CodePipeline (Triggered)
         ↓
   AWS CodeBuild
   ├── Build Docker image (PHP 8.1 + WordPress)
   ├── Run tests
   └── Push image to Amazon ECR
         ↓
   AWS CodeDeploy
   └── Blue/Green deployment to ECS Fargate
         ├── Start new task set (Green)
         ├── ALB shifts traffic gradually
         ├── Health check validation
         └── Terminate old task set (Blue) → Zero downtime
```

---

## 💰 Cost Estimation

**Region:** Europe (Frankfurt) | **Date:** January 2026

| Service | Monthly Cost |
|---------|-------------|
| AWS Fargate | $198.99 |
| Amazon CloudFront | $285.72 |
| Amazon RDS (MariaDB Multi-AZ) | $138.14 |
| Amazon ElastiCache (Memcached) | $52.56 |
| Amazon VPC (NAT Gateways) | $97.27 |
| Amazon CloudWatch | $41.59 |
| Elastic Load Balancing (ALB) | $36.06 |
| AWS WAF | $16.00 |
| Amazon EC2 (VPN/Bastion) | $2.86 |
| Amazon S3 | $1.23 |
| Amazon EFS | $0.72 |
| AWS Backup | $3.44 |
| Amazon ECR | $1.00 |
| Amazon Route 53 | $0.00 |
| **Total Monthly** | **~$875.58** |
| **Upfront (Savings Plan)** | **$98.99** |
| **Total 12 Months** | **~$10,605.95** |


---

## 📐 Project Phases

This project was completed in 4 structured phases:

### Phase 1 — Architecture Design
- Analyzed requirements: traffic patterns, SEO constraints, DDoS exposure, backup requirements
- Designed AWS architecture using **Draw.io**
- Selected services based on WordPress-specific needs (Memcached, EFS, MariaDB)

### Phase 2 — Cost Estimation
- Calculated monthly and annual costs using **AWS Pricing Calculator**
- Evaluated trade-offs between On-Demand vs Reserved pricing
- Presented cost breakdown per service

### Phase 3 — Detailed Network Design
- Defined VPC CIDR block: `10.0.0.0/16`
- Designed 6-subnet architecture across 2 AZs (Public / App Private / Data Private)
- Configured route tables, NAT Gateways, and Internet Gateway
- Defined security group rules per layer

### Phase 4 — POC (Proof of Concept)
- Implemented Phase 1 architecture as a working POC
- Validated ECS task connectivity, EFS mount, RDS access
- Tested ALB health checks and traffic distribution

---


---

## 📄 License

This project is a scenario-based infrastructure design study. Architecture patterns and configurations are provided for educational and reference purposes.

---

> **Built for:** High-traffic WordPress on AWS | **Region:** eu-central-1 (Frankfurt) | **Version:** V-0.1
