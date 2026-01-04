#  NT548 LAB 01 - AWS Infrastructure as Code

> **Triển khai hạ tầng AWS tự động với CloudFormation và Terraform**

---

##  MỤC LỤC

- [Giới thiệu](#-giới-thiệu)
- [Kiến trúc hệ thống](#️-kiến-trúc-hệ-thống)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [So sánh CloudFormation vs Terraform](#-so-sánh-cloudformation-vs-terraform)
---

##  GIỚI THIỆU

Repository này chứa 2 phiên bản triển khai hạ tầng AWS hoàn toàn tương đồng, sử dụng 2 công cụ Infrastructure as Code (IaC) phổ biến nhất:

###  **CloudFormation** - AWS Native Tool
- ✅ Tích hợp sẵn với AWS, không cần cài đặt thêm
- ✅ Hỗ trợ rollback tự động khi có lỗi
- ✅ Change Sets để preview thay đổi trước khi apply
- ✅ 3 phương thức triển khai:
  - **Single Stack** (main.yaml): Tất cả resources trong 1 file
  - **Nested Stacks** (main-nested.yaml): Modular với S3 bucket
  - **Standalone Modules**: 4 modules độc lập không phụ thuộc S3

###  **Terraform** - Multi-Cloud Platform
- ✅ Cú pháp HCL dễ đọc, dễ học
- ✅ Modular architecture với 7 modules độc lập
- ✅ State management cho tracking changes
- ✅ Test suite tự động với 19 test cases
- ✅ Có thể tái sử dụng cho AWS, Azure, GCP

### 🎓 **Mục đích học tập**
- So sánh và đối chiếu giữa 2 công cụ IaC phổ biến
- Hiểu rõ ưu/nhược điểm của từng approach
- Thực hành best practices trong DevOps
- Tự động hóa hoàn toàn quy trình triển khai

---

##  KIẾN TRÚC HỆ THỐNG

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
│  │  │  │ │ Public IP: ✓  │ │   │    │  │ │ Public IP: ✗ │ │  │  │  │
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

###  Luồng traffic

1. **Internet → Public EC2 (SSH):**
   - User IP → Internet Gateway → Public EC2
   -  **Bảo mật**: SSH chỉ từ IP được chỉ định (yêu cầu 2 điểm)

2. **Public EC2 → Private EC2 (Bastion/Jump Host):**
   - Public EC2 → Private EC2
   - Security Group cho phép toàn bộ traffic từ Public SG

3. **Private EC2 → Internet (Outbound only):**
   - Private EC2 → NAT Gateway → Internet Gateway → Internet
   -  **Private EC2 không có Public IP** (yêu cầu đề bài)
   -  Có thể access Internet nhưng không nhận inbound traffic

###  Tài nguyên AWS được triển khai

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

##  CẤU TRÚC DỰ ÁN

```
LAB01/
│
├── README.md                          # ← File này (tổng quan repo)
├── bucket-policy-temp.json            # S3 bucket policy template
│
├── CloudFormation/                    # ══════ AWS CloudFormation ══════
│   ├── README.md                      #  Hướng dẫn chi tiết CloudFormation
│   │
│   ├── main.yaml                      #  Single Stack (tất cả trong 1 file)
│   ├── main-nested.yaml               #  Nested Stacks (modular với S3)
│   ├── parameters.json                #  Stack parameters
│   │
│   ├── deploy.ps1                     #  Deploy main.yaml
│   ├── deploy-all-modules.ps1         #  Deploy tất cả standalone modules
│   ├── delete.ps1                     #  Xóa stack
│   ├── delete-all-modules.ps1         #  Xóa tất cả modules
│   ├── test-stack.ps1                 #  Test stack status
│   ├── ssh-connect.ps1                #  SSH connection helper
│   ├── copy-key-and-connect.ps1       #  Copy SSH key & connect
│   │
│   ├── bucket-policy.json             # S3 bucket policy
│   ├── bucket-policy-fix.json         # S3 bucket policy (fixed)
│   ├── working-key-pub.txt            # SSH public key
│   │
│   └── standalone-modules/            #  Standalone Modules (không cần S3)
│       ├── README.md                  #  Hướng dẫn standalone modules
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
└── Terraform/                         # ══════ HashiCorp Terraform ══════
    ├── README.md                      #  Hướng dẫn chi tiết Terraform
    │
    ├── main.tf                        #  Main configuration (gọi modules)
    ├── variables.tf                   #  Variable definitions
    ├── outputs.tf                     #  Output values
    ├── provider.tf                    #  AWS provider config
    │
    ├── terraform.tfvars               #  Actual values (gitignored)
    ├── terraform.tfvars.example       #  Example configuration
    │
    ├── terraform.tfstate              #  State file (gitignored)
    ├── terraform.tfstate.backup       #  State backup
    │
    ├── modules/                       #  Terraform Modules
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
    └── tests/                         #  Test Suite
        └── test-services.ps1          # 19 automated tests
```

---

##  YÊU CẦU HỆ THỐNG

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
-  AWS Account với IAM user có quyền:
  - EC2 (VPC, Subnets, IGW, NAT, Security Groups, Instances)
  - CloudFormation (cho CloudFormation approach)
  - IAM (tối thiểu read access)
-  AWS Access Key & Secret Key
-  EC2 Key Pair (tạo trước hoặc dùng scripts tự động)

### Tài nguyên AWS Free Tier
-  **t3.micro** instances (750 hours/month miễn phí)
-  **NAT Gateway** KHÔNG miễn phí (~$0.045/hour + data transfer)
-  Chi phí ước tính: ~$3-4/month nếu chạy 24/7

---

##  SO SÁNH CLOUDFORMATION VS TERRAFORM

###  Bảng so sánh tổng quan

| Tiêu chí | CloudFormation | Terraform |
|----------|----------------|-----------|
| **Nhà cung cấp** | AWS (Amazon) | HashiCorp |
| **Cú pháp** | YAML/JSON | HCL (HashiCorp Language) |
| **Multi-cloud** | ❌ Chỉ AWS | ✅ AWS, Azure, GCP, etc. |
| **Cài đặt** | Không cần (built-in AWS) | Cần cài Terraform CLI |
| **State Management** | Tự động (AWS quản lý) | File .tfstate (cần quản lý) |
| **Rollback** | ✅ Tự động | ❌ Thủ công |
| **Change Preview** | Change Sets | `terraform plan` |
| **Độ phổ biến** | AWS-only shops | Multi-cloud teams |
| **Learning Curve** | Trung bình | Dễ học hơn |
| **Module Ecosystem** | AWS Service Catalog | Terraform Registry |

###  Khi nào dùng gì?

#### Chọn **CloudFormation** khi:
-  Làm việc chỉ với AWS
-  Muốn tích hợp sâu với AWS services
-  Cần rollback tự động
-  Không muốn quản lý state files
-  Team đã quen với AWS ecosystem

#### Chọn **Terraform** khi:
-  Multi-cloud strategy (AWS + Azure + GCP)
-  Muốn cú pháp đơn giản, dễ đọc
-  Cần modules tái sử dụng cao
-  Ưa thích declarative syntax
-  Có kinh nghiệm với HashiCorp tools




#   N T 5 4 8 . Q 1 1 _ L A B 0 1 - N h o m 0 6  
 