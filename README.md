# ECS DevOps Project (03-04)

Terraform project that provisions a containerised application on **AWS ECS Fargate** with an **Application Load Balancer** in `ap-south-1`.

---

## Architecture

```
Internet
   │  HTTP :80
   ▼
ALB (alb-sg)
   │  port 5000 (internal)
   ▼
ECS Fargate Tasks  ──►  ECR (container image)
   (ecs-sg, awsvpc)
   │
   VPC: 10.0.0.0/16
   ├── public-subnet-1  ap-south-1a  10.0.1.0/24
   └── public-subnet-2  ap-south-1b  10.0.2.0/24
```

---

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider – region `ap-south-1` |
| `variables.tf` | Project-level variables |
| `vpc.tf` | VPC, subnets, IGW, route tables |
| `ecr.tf` | ECR repository with scan-on-push |
| `alb.tf` | ALB, Target Group, HTTP Listener, ALB security group |
| `ecs.tf` | ECS Cluster, Task Definition, IAM Role, ECS Service |
| `outputs.tf` | ALB DNS, ECR URL, cluster name |

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

After apply, push your image to ECR:

```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin <ecr_repository_url>

docker build -t ecs-devops-repo .
docker tag  ecs-devops-repo:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

Access the app via the ALB DNS output:

```
http://<alb_dns_name>
```

---

## Changes & Fixes Applied

- **ALB added** – `alb.tf` with ALB SG, Target Group (type `ip` for Fargate), HTTP listener on port 80
- **ECS SG hardened** – Tasks now only accept inbound traffic **from the ALB SG** (previously open to `0.0.0.0/0`)
- **ECS Service** wired to ALB Target Group via `load_balancer` block; `depends_on` listener ensures correct creation order
- **desired_count raised to 2** – one task per AZ for high availability
- **`app_port` variable** – single source of truth for container port (5000); used across `ecs.tf` and `alb.tf`
- **`outputs.tf` added** – exposes ALB DNS, ECR URL, cluster name after apply
