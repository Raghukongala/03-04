# ECS DevOps Project (03-04)

Terraform project that provisions a containerised application on **AWS ECS Fargate** with an **Application Load Balancer** and **Auto Scaling** in `ap-south-1`.

---

## Architecture

```
Internet
   │  HTTP :80
   ▼
┌─────────────────────────────────┐
│  ALB  (alb-sg)                  │
│  ecs-devops-alb                 │
└────────────┬────────────────────┘
             │ port 5000 (internal)
             ▼
┌─────────────────────────────────┐
│  ECS Fargate Tasks  (ecs-sg)    │
│  min=2  max=6  (auto scaled)    │
│  AZ-a (subnet-1)                │
│  AZ-b (subnet-2)                │
└────────────┬────────────────────┘
             │ pulls image
             ▼
        ECR Repository

VPC: 10.0.0.0/16
 ├── public-subnet-1  ap-south-1a  10.0.1.0/24
 └── public-subnet-2  ap-south-1b  10.0.2.0/24
```

---

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider – region `ap-south-1` |
| `variables.tf` | All project-level variables |
| `vpc.tf` | VPC, subnets, IGW, route tables |
| `ecr.tf` | ECR repository with scan-on-push |
| `alb.tf` | ALB, Target Group, HTTP Listener, ALB SG |
| `ecs.tf` | ECS Cluster, Task Definition, IAM Role, Service |
| `autoscaling.tf` | App Auto Scaling – CPU, Memory, ALB RPS policies + CW Alarm |
| `outputs.tf` | ALB DNS, ECR URL, cluster name, scaling min/max |

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | `ecs-devops-project` | Prefix for resource names |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `app_port` | `5000` | Container port (used across ALB, ECS, SG) |
| `ecs_min_capacity` | `2` | Minimum running ECS tasks |
| `ecs_max_capacity` | `6` | Maximum running ECS tasks |

---

## Auto Scaling Policies

| Policy | Metric | Target | Scale-out | Scale-in |
|--------|--------|--------|-----------|----------|
| `cpu_scaling` | ECS Average CPU % | 60% | 60s | 300s |
| `memory_scaling` | ECS Average Memory % | 70% | 60s | 300s |
| `alb_request_scaling` | ALB Requests per Target | 1000 req | 60s | 300s |

A CloudWatch Alarm (`ecs-high-cpu`) fires when CPU stays above **80% for 2 minutes**.

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Override defaults if needed:
```bash
terraform apply \
  -var="ecs_min_capacity=2" \
  -var="ecs_max_capacity=10"
```

Push your image to ECR after apply:
```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin <ecr_repository_url>

docker build -t ecs-devops-repo .
docker tag  ecs-devops-repo:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

Access the app:
```
http://<alb_dns_name>
```

---

## All Changes & Fixes Applied

| # | Change | File |
|---|--------|------|
| 1 | ECS SG only accepts traffic from ALB SG (was open to 0.0.0.0/0) | `ecs.tf` |
| 2 | ECS Service wired to ALB Target Group via load_balancer block | `ecs.tf` |
| 3 | desired_count uses var.ecs_min_capacity (was hardcoded 1) | `ecs.tf` |
| 4 | Port 5000 centralised into var.app_port | `variables.tf` |
| 5 | ALB + Target Group (type ip) + HTTP Listener added | `alb.tf` (new) |
| 6 | Auto Scaling: CPU, Memory, ALB RPS policies + CW Alarm | `autoscaling.tf` (new) |
| 7 | ecs_min_capacity / ecs_max_capacity variables added | `variables.tf` |
| 8 | outputs.tf added – ALB DNS, ECR URL, cluster name, scale min/max | `outputs.tf` (new) |

---

## CI/CD Pipeline — GitHub Actions

### Pipeline file
`.github/workflows/deploy.yml`

### Triggers

| Event | What runs |
|-------|-----------|
| `push` to `main` | Build → Push ECR → Deploy ECS |
| `workflow_dispatch` → `plan` | Terraform plan only |
| `workflow_dispatch` → `apply` | Terraform apply (provision infra) |
| `workflow_dispatch` → `destroy` | Terraform destroy (tear down) |
| `workflow_dispatch` → `none` | Build → Push ECR → Deploy ECS (manual) |

### Jobs

```
push to main
     │
     ├─── build  ──────────────────────────────────────────────┐
     │    1. docker build (with layer cache)                   │
     │    2. docker push :SHA + :latest to ECR                 │
     │    3. trivy scan (CRITICAL/HIGH)                        │
     │                                                         │
     └─── deploy  (needs: build, env: production) ────────────┘
          1. Download current task def from AWS
          2. Inject new image URI → new task def revision
          3. ecs deploy + wait for stability
```

### GitHub Secrets required

Go to **Settings → Secrets → Actions** and add:

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

### IAM permissions needed for the pipeline user

```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:PutImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecs:DescribeTaskDefinition",
    "ecs:RegisterTaskDefinition",
    "ecs:UpdateService",
    "ecs:DescribeServices",
    "iam:PassRole"
  ],
  "Resource": "*"
}
```

### Deploy flow

```
git push origin main
        │
        ▼
  GitHub Actions
        │
   ┌────┴────┐
   │  build  │  docker build → ECR push → trivy scan
   └────┬────┘
        │
   ┌────┴──────┐
   │  deploy   │  new task def → ECS rolling update → health check
   └───────────┘
        │
        ▼
  http://<alb_dns_name>  ✅
```
