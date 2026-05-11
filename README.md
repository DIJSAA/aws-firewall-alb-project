## Security Design

Defense in depth with three layers:
1. **Network ACL** — stateless firewall at subnet level. Allows only HTTP, HTTPS, and return traffic
2. **ALB Security Group** — allows HTTP/HTTPS inbound from internet
3. **EC2 Security Group** — allows traffic from ALB only. EC2s have no public IP and cannot be reached directly

## Routing Rules

| Path | Backend |
|------|---------|
| /app1* | App Server 1 |
| /app2* | App Server 2 |
| /* (default) | App Server 1 |

## High Availability

Deployed across 2 Availability Zones (us-east-1a, us-east-1b). ALB health checks remove unhealthy instances automatically.

## Tech Stack

- **Cloud:** AWS us-east-1
- **IaC:** Terraform
- **Compute:** EC2 t3.micro
- **Networking:** VPC, NACLs, Security Groups, ALB

## Project Structure
├── main.tf          # VPC, subnets, NACLs, security groups
├── alb.tf           # EC2, ALB, target groups, routing rules
├── variables.tf     # Input variable definitions
└── terraform.tfvars # Variable values

## Deployment

```bash
terraform init
terraform plan
terraform apply
terraform destroy  # always destroy when done to avoid costs
```

## Concepts Demonstrated

- Multi-tier network architecture with public and private subnets
- Stateless vs stateful firewall (NACLs vs Security Groups)
- Application Load Balancer with path-based routing
- Security group chaining — EC2 only reachable via ALB
- Multi-AZ high availability design
- Infrastructure as Code with Terraform
