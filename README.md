# NT548 LAB 01 - AWS Infrastructure as Code

> **Triển khai hạ tầng AWS tự động với CloudFormation và Terraform**

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)](https://www.terraform.io/)
[![CloudFormation](https://img.shields.io/badge/CloudFormation-IaC-blue?logo=amazon-aws)](https://aws.amazon.com/cloudformation/)
[![PowerShell](https://img.shields.io/badge/PowerShell-Automation-blue?logo=powershell)](https://docs.microsoft.com/powershell/)

---

## MỤC LỤC

- [Giới thiệu](#giới-thiệu)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [So sánh CloudFormation vs Terraform](#so-sánh-cloudformation-vs-terraform)
- [Hướng dẫn triển khai](#hướng-dẫn-triển-khai)
- [Tính năng nổi bật](#tính-năng-nổi-bật)
- [Kiểm thử và xác thực](#kiểm-thử-và-xác-thực)
- [Troubleshooting](#troubleshooting)
- [Tài liệu chi tiết](#tài-liệu-chi-tiết)

---

## GIỚI THIỆU

Repository này chứa 2 phiên bản triển khai hạ tầng AWS hoàn toàn tương đồng, sử dụng 2 công cụ Infrastructure as Code (IaC) phổ biến nhất:

### CloudFormation - AWS Native Tool

- Tích hợp sẵn với AWS, không cần cài đặt thêm
- Hỗ trợ rollback tự động khi có lỗi
- Change Sets để preview thay đổi trước khi apply
- 3 phương thức triển khai:
  - **Single Stack** (main.yaml): Tất cả resources trong 1 file
  - **Nested Stacks** (main-nested.yaml): Modular với S3 bucket
  - **Standalone Modules**: 4 modules độc lập không phụ thuộc S3

### Terraform - Multi-Cloud Platform

- Cú pháp HCL dễ đọc, dễ học
- Modular architecture với 7 modules độc lập
- State management cho tracking changes
- Test suite tự động với 19 test cases
- Có thể tái sử dụng cho AWS, Azure, GCP

### Mục đích học tập

- So sánh và đối chiếu giữa 2 công cụ IaC phổ biến
- Hiểu rõ ưu/nhược điểm của từng approach
- Thực hành best practices trong DevOps
- Tự động hóa hoàn toàn quy trình triển khai

---

## KIẾN TRÚC HỆ THỐNG

### Sơ đồ kiến trúc

```
┌──────────────────────────────────────────────────────────────────────┐
│                           AWS CLOUD                                  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                             │  │
│  │                                                                │  │
│  │  ┌──────────────────────────┐    ┌─────────────────────────┐  │  │
│  │  │ Public Subnet            │    │ Private Subnet          │  │  │
│  │  │ (10.0.1.0/24)            │    │ (10.0.2.0/24)           │  │  │
│  │  │                          │    │                         │  │  │
│  │  │  ┌───────────────────┐   │    │  ┌──────────────────┐  │  │  │
│  │  │  │ Public EC2        │   │    │  │ Private EC2      │  │  │  │
│  │  │  │ ┌───────────────┐ │   │    │  │ ┌──────────────┐ │  │  │  │
│  │  │  │ │ Ubuntu 24.04  │ │   │    │  │ │ Ubuntu 24.04 │ │  │  │  │
│  │  │  │ │ t3.micro      │ │   │    │  │ │ t3.micro     │ │  │  │  │
│  │  │  │ │ Public IP: Yes│ │   │    │  │ │ Public IP: No│ │  │  │  │
│  │  │  │ └───────────────┘ │   │    │  │ └──────────────┘ │  │  │  │
│  │  │  └─────────┬─────────┘   │    │  └────────┬─────────┘  │  │  │
│  │  │            │             │    │           │            │  │  │
│  │  │  ┌─────────┴──────────┐  │    │           │            │  │  │
│  │  │  │ NAT Gateway        │  │    │           │            │  │  │
│  │  │  │ Elastic IP         │◄─┼────┼───────────┘            │  │  │
│  │  │  └─────────┬──────────┘  │    │                        │  │  │
│  │  └────────────┼─────────────┘    └────────────────────────┘  │  │
│  │               │                                                │  │
│  │  ┌────────────┴─────────────────────────────────────────────┐ │  │
│  │  │         Internet Gateway                                 │ │  │
│  │  └────────────┬─────────────────────────────────────────────┘ │  │
│  └───────────────┼───────────────────────────────────────────────┘  │
│                  │                                                   │
└──────────────────┼───────────────────────────────────────────────────┘
                   │
           ┌───────┴────────┐
           │   INTERNET     │
           │                │
           │  Your PC       │
           │  (SSH Access)  │
           └────────────────┘
```

### Luồng traffic

1. **Internet → Public EC2 (SSH):**
   - User IP → Internet Gateway → Public EC2
   - **Bảo mật**: SSH chỉ từ IP được chỉ định (yêu cầu 2 điểm)

2. **Public EC2 → Private EC2 (Bastion/Jump Host):**
   - Public EC2 → Private EC2
   - Security Group cho phép toàn bộ traffic từ Public SG

3. **Private EC2 → Internet (Outbound only):**
   - Private EC2 → NAT Gateway → Internet Gateway → Internet
   - **Private EC2 không có Public IP** (yêu cầu đề bài)
   - Có thể access Internet nhưng không nhận inbound traffic

### Tài nguyên AWS được triển khai

| Resource | Số lượng | Mục đích |
|----------|----------|----------|
| VPC | 1 | Network isolation |
| Subnets | 2 | Public/Private separation |
| Internet Gateway | 1 | Internet access cho Public subnet |
| NAT Gateway | 1 | Internet access cho Private subnet |
| Elastic IP | 1 | Static IP cho NAT Gateway |
| Route Tables | 2 | Routing rules |
| Security Groups | 2 | Firewall rules |
| EC2 Instances | 2 | Computing resources (t3.micro - Free Tier) |

---

## CẤU TRÚC DỰ ÁN

```
LAB01/
│
├── README.md                          # File này (tổng quan repo)
├── bucket-policy-temp.json            # S3 bucket policy template
│
├── CloudFormation/                    # AWS CloudFormation
│   ├── README.md                      # Hướng dẫn chi tiết CloudFormation
│   │
│   ├── main.yaml                      # Single Stack (tất cả trong 1 file)
│   ├── main-nested.yaml               # Nested Stacks (modular với S3)
│   ├── parameters.json                # Stack parameters
│   │
│   ├── deploy.ps1                     # Deploy main.yaml
│   ├── deploy-all-modules.ps1         # Deploy tất cả standalone modules
│   ├── delete.ps1                     # Xóa stack
│   ├── delete-all-modules.ps1         # Xóa tất cả modules
│   ├── test-stack.ps1                 # Test stack status
│   ├── ssh-connect.ps1                # SSH connection helper
│   ├── copy-key-and-connect.ps1       # Copy SSH key & connect
│   │
│   ├── bucket-policy.json             # S3 bucket policy
│   ├── bucket-policy-fix.json         # S3 bucket policy (fixed)
│   ├── working-key-pub.txt            # SSH public key
│   │
│   └── standalone-modules/            # Standalone Modules (không cần S3)
│       ├── README.md                  # Hướng dẫn standalone modules
│       │
│       ├── vpc/                       # Module 1: VPC
│       │   ├── vpc.yaml               # VPC infrastructure
│       │   └── deploy-vpc.ps1         # Deploy script
│       │
│       ├── network/                   # Module 2: Network
│       │   ├── network.yaml           # Subnets, IGW, NAT, Routes
│       │   └── deploy-network.ps1     # Deploy script
│       │
│       ├── security/                  # Module 3: Security Groups
│       │   ├── security.yaml          # Security Groups
│       │   └── deploy-security.ps1    # Deploy script
│       │
│       └── ec2/                       # Module 4: EC2 Instances
│           ├── ec2.yaml               # EC2 configuration
│           └── deploy-ec2.ps1         # Deploy script
│
└── Terraform/                         # HashiCorp Terraform
    ├── README.md                      # Hướng dẫn chi tiết Terraform
    │
    ├── main.tf                        # Main configuration (gọi modules)
    ├── variables.tf                   # Variable definitions
    ├── outputs.tf                     # Output values
    ├── provider.tf                    # AWS provider config
    │
    ├── terraform.tfvars               # Actual values (gitignored)
    ├── terraform.tfvars.example       # Example configuration
    │
    ├── terraform.tfstate              # State file (gitignored)
    ├── terraform.tfstate.backup       # State backup
    │
    ├── modules/                       # Terraform Modules
    │   ├── vpc/                       # Module 1: VPC
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── subnet/                    # Module 2: Subnet
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── internet_gateway/          # Module 3: Internet Gateway
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── nat_gateway/               # Module 4: NAT Gateway
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── route_table/               # Module 5: Route Tables
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── security_group/            # Module 6: Security Groups
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   └── ec2/                       # Module 7: EC2 Instances
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── user_data_public.sh    # Public EC2 startup script
    │       └── user_data_private.sh   # Private EC2 startup script
    │
    └── tests/                         # Test Suite
        └── test-services.ps1          # 19 automated tests
```

---

## YÊU CẦU HỆ THỐNG

### Phần mềm cần thiết

#### Cho CloudFormation:

```powershell
# AWS CLI
aws --version
# AWS CLI 2.x trở lên

# PowerShell
$PSVersionTable.PSVersion
# PowerShell 5.1 trở lên (Windows) hoặc PowerShell Core 7+ (Cross-platform)
```

#### Cho Terraform:

```powershell
# Terraform
terraform version
# Terraform v1.0 trở lên

# AWS CLI (optional, for testing)
aws --version
```

### AWS Account Requirements

- AWS Account với IAM user có quyền:
  - EC2 (VPC, Subnets, IGW, NAT, Security Groups, Instances)
  - CloudFormation (cho CloudFormation approach)
  - IAM (tối thiểu read access)
- AWS Access Key & Secret Key
- EC2 Key Pair (tạo trước hoặc dùng scripts tự động)

### Tài nguyên AWS Free Tier

- **t3.micro** instances (750 hours/month miễn phí)
- **NAT Gateway** KHÔNG miễn phí (~$0.045/hour + data transfer)
- Chi phí ước tính: ~$3-4/month nếu chạy 24/7

---

## SO SÁNH CLOUDFORMATION VS TERRAFORM

### Bảng so sánh tổng quan

| Tiêu chí | CloudFormation | Terraform |
|----------|----------------|-----------|
| **Nhà cung cấp** | AWS (Amazon) | HashiCorp |
| **Cú pháp** | YAML/JSON | HCL (HashiCorp Language) |
| **Multi-cloud** | Chỉ AWS | AWS, Azure, GCP, etc. |
| **Cài đặt** | Không cần (built-in AWS) | Cần cài Terraform CLI |
| **State Management** | Tự động (AWS quản lý) | File .tfstate (cần quản lý) |
| **Rollback** | Tự động | Thủ công |
| **Change Preview** | Change Sets | `terraform plan` |
| **Độ phổ biến** | AWS-only shops | Multi-cloud teams |
| **Learning Curve** | Trung bình | Dễ học hơn |
| **Module Ecosystem** | AWS Service Catalog | Terraform Registry |

### Khi nào dùng gì?

#### Chọn CloudFormation khi:

- Làm việc chỉ với AWS
- Muốn tích hợp sâu với AWS services
- Cần rollback tự động
- Không muốn quản lý state files
- Team đã quen với AWS ecosystem

#### Chọn Terraform khi:

- Multi-cloud strategy (AWS + Azure + GCP)
- Muốn cú pháp đơn giản, dễ đọc
- Cần modules tái sử dụng cao
- Ưa thích declarative syntax
- Có kinh nghiệm với HashiCorp tools

### So sánh code (tạo VPC)

#### CloudFormation (YAML):

```yaml
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-vpc
```

#### Terraform (HCL):

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
```

**Nhận xét**: Terraform ngắn gọn và dễ đọc hơn!

---

## HƯỚNG DẪN TRIỂN KHAI

### CloudFormation Deployment

#### Option 1: Single Stack (Đơn giản nhất)

```powershell
# Di chuyển vào thư mục CloudFormation
cd CloudFormation

# Chỉnh sửa parameters.json với thông tin của bạn
# - KeyName: Tên key pair AWS
# - MyIP: IP address của bạn

# Deploy
.\deploy.ps1

# Kiểm tra status
.\test-stack.ps1

# Kết nối SSH
.\ssh-connect.ps1
```

#### Option 2: Nested Stacks (Modular)

```powershell
# Tạo S3 bucket trước (xem hướng dẫn trong CloudFormation/README.md)

# Deploy nested stacks
aws cloudformation create-stack `
  --stack-name nt548-lab01-nested `
  --template-body file://main-nested.yaml `
  --parameters file://parameters.json
```

#### Option 3: Standalone Modules

```powershell
# Deploy tất cả modules
.\deploy-all-modules.ps1

# Hoặc deploy từng module riêng lẻ
.\standalone-modules\vpc\deploy-vpc.ps1
.\standalone-modules\network\deploy-network.ps1
.\standalone-modules\security\deploy-security.ps1
.\standalone-modules\ec2\deploy-ec2.ps1
```

### Terraform Deployment

```powershell
# Di chuyển vào thư mục Terraform
cd Terraform

# 1. Copy file cấu hình mẫu
cp terraform.tfvars.example terraform.tfvars

# 2. Chỉnh sửa terraform.tfvars
# - aws_access_key: AWS Access Key của bạn
# - aws_secret_key: AWS Secret Key của bạn
# - my_ip: IP address của bạn
# - ec2_key_name: Tên key pair AWS

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Deploy infrastructure
terraform apply
# Nhập 'yes' để confirm

# 6. Kiểm tra outputs
terraform output

# 7. Chạy tests (optional)
.\tests\test-services.ps1
```

### Kết nối SSH

#### Kết nối đến Public EC2:

```powershell
# Lấy Public IP từ outputs
# CloudFormation:
aws cloudformation describe-stacks `
  --stack-name nt548-lab01 `
  --query 'Stacks[0].Outputs'

# Terraform:
terraform output public_ec2_public_ip

# SSH
ssh -i "path/to/your-key.pem" ubuntu@<PUBLIC_IP>
```

#### Kết nối đến Private EC2 (qua Bastion):

```powershell
# Copy SSH key vào Public EC2
scp -i "your-key.pem" your-key.pem ubuntu@<PUBLIC_IP>:~/.ssh/

# SSH vào Public EC2
ssh -i "your-key.pem" ubuntu@<PUBLIC_IP>

# Từ Public EC2, SSH vào Private EC2
ssh -i ~/.ssh/your-key.pem ubuntu@<PRIVATE_IP>
```

---

## TÍNH NĂNG NỔI BẬT

### CloudFormation

- **3 phương thức triển khai** khác nhau để học tập
- **Auto-rollback** khi deployment thất bại
- **Change Sets** để preview thay đổi
- **DependsOn** tự động quản lý dependencies
- **PowerShell scripts** tự động hóa deployment
- **Comprehensive outputs** hiển thị mọi thông tin cần thiết

### Terraform

- **7 modules độc lập** dễ tái sử dụng
- **State management** tracking infrastructure changes
- **Declarative syntax** dễ đọc, dễ bảo trì
- **19 automated tests** đảm bảo quality
- **User data scripts** tự động cài đặt packages
- **Detailed outputs** với mã màu PowerShell

### Bảo mật

- SSH access chỉ từ IP được chỉ định
- Private EC2 không có Public IP
- Security Groups tuân thủ least privilege
- Bastion host architecture (Public → Private)

---

## KIỂM THỬ VÀ XÁC THỰC

### CloudFormation Testing

```powershell
# Kiểm tra stack status
.\test-stack.ps1

# Manual verification
aws cloudformation describe-stacks --stack-name nt548-lab01

# Kiểm tra resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=nt548-lab01"
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=nt548-lab01"
```

### Terraform Testing

```powershell
# Chạy automated test suite (19 tests)
.\tests\test-services.ps1

# Manual verification
terraform show
terraform state list

# Kiểm tra connectivity
# Test 1: SSH vào Public EC2
ssh -i "key.pem" ubuntu@<PUBLIC_IP>

# Test 2: Từ Public EC2, kiểm tra internet access của Private EC2
# (xem chi tiết trong Terraform/README.md)
```

---

## TROUBLESHOOTING

### Lỗi thường gặp

#### 1. SSH Connection Refused

```
Nguyên nhân: Security Group chưa cho phép IP của bạn
Giải pháp: Kiểm tra lại my_ip/MyIP trong config
```

#### 2. NAT Gateway Creation Failed

```
Nguyên nhân: EIP quota exceeded hoặc không có Internet Gateway
Giải pháp: 
- Xóa EIPs không dùng
- Kiểm tra Internet Gateway đã được tạo
```

#### 3. Stack Creation Failed (CloudFormation)

```
Giải pháp:
- Xem Events trong CloudFormation Console
- Chạy: aws cloudformation describe-stack-events --stack-name nt548-lab01
```

#### 4. State Lock Error (Terraform)

```
Nguyên nhân: Terraform state file bị lock
Giải pháp:
terraform force-unlock <LOCK_ID>
```

#### 5. Invalid Key Pair

```
Nguyên nhân: Key pair không tồn tại trong region
Giải pháp:
- Tạo key pair mới trong AWS Console
- Hoặc chạy: aws ec2 create-key-pair --key-name nt548-lab01-key
```

### Xóa hạ tầng

#### CloudFormation:

```powershell
# Xóa single/nested stack
.\delete.ps1

# Xóa tất cả standalone modules
.\delete-all-modules.ps1

# Manual deletion
aws cloudformation delete-stack --stack-name nt548-lab01
```

#### Terraform:

```powershell
# Xóa toàn bộ infrastructure
terraform destroy

# Confirm với 'yes'
```

**Lưu ý**: NAT Gateway và EIP có thể mất vài phút để xóa hoàn toàn.

---

## TÀI LIỆU CHI TIẾT

### Hướng dẫn chi tiết cho từng công cụ:

- [CloudFormation README.md](CloudFormation/README.md) - Hướng dẫn đầy đủ cho CloudFormation
- [Terraform README.md](Terraform/README.md) - Hướng dẫn đầy đủ cho Terraform
- [Standalone Modules README.md](CloudFormation/standalone-modules/README.md) - Hướng dẫn modules độc lập

### Tài liệu tham khảo AWS:

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## HỌC TẬP VÀ MỞ RỘNG

### Điều bạn học được từ repo này:

**1. Infrastructure as Code (IaC)**
- Tự động hóa deployment
- Version control cho infrastructure
- Reproducibility và consistency

**2. AWS Networking**
- VPC, Subnets, Route Tables
- Internet Gateway và NAT Gateway
- Security Groups và Network ACLs

**3. Security Best Practices**
- Least privilege access
- Bastion host architecture
- IP whitelisting

**4. DevOps Practices**
- Automation với PowerShell
- Testing infrastructure
- Documentation

### Bài tập mở rộng:

- Thêm Application Load Balancer
- Triển khai Multi-AZ với High Availability
- Tích hợp với AWS Systems Manager (Session Manager)
- Thêm CloudWatch monitoring và alerts
- Implement Auto Scaling Groups
- Thêm RDS database trong Private Subnet

---

## NGƯỜI THỰC HIỆN

**Course**: NT548 - DevOps and Infrastructure as Code  
**Lab**: LAB 01 - AWS Infrastructure with CloudFormation & Terraform  
**Semester**: 2024-2025

---

## LICENSE

This project is for educational purposes only.

---

## ĐÓNG GÓP

Mọi đóng góp, góp ý, hoặc báo lỗi đều được hoan nghênh!

1. Fork repo
2. Tạo branch mới (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Tạo Pull Request

---

## LIÊN HỆ

Nếu có thắc mắc hoặc cần hỗ trợ:
- Email: [Your Email]
- Issues: [GitHub Issues]

---

<div align="center">

**Nếu repo này hữu ích, hãy cho một star!**

Made with love for learning DevOps

</div>
