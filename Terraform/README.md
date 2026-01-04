#  NT548 LAB 01 - AWS Infrastructure as Code with Terraform

##  MỤC LỤC
- [Giới thiệu](#-giới-thiệu)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt và cấu hình](#-cài-đặt-và-cấu-hình)
- [Hướng dẫn triển khai](#-hướng-dẫn-triển-khai)
- [Kiểm thử hệ thống](#-kiểm-thử-hệ-thống)
- [Kết nối SSH](#-kết-nối-ssh)
- [Chi tiết modules](#-chi-tiết-modules)
- [Troubleshooting](#-troubleshooting)
- [Tài liệu tham khảo](#-tài-liệu-tham-khảo)

---

##  GIỚI THIỆU

### Mục đích
Dự án này sử dụng **Terraform** (Infrastructure as Code) để tự động triển khai một hạ tầng AWS hoàn chỉnh, bao gồm:
-  Virtual Private Cloud (VPC) với 2 subnets (Public & Private)
-  Internet Gateway cho Public Subnet
-  NAT Gateway cho Private Subnet ra Internet
-  Route Tables với routing rules
-  Security Groups với firewall rules
-  2 EC2 instances (t3.micro - Free Tier eligible)
-  Automated testing suite (19 test cases)

### Đặc điểm nổi bật
-  **Modular Architecture**: 7 modules độc lập, dễ bảo trì và mở rộng
-  **Security-focused**: Security Groups tuân thủ best practices
-  **Fully Tested**: Test suite tự động cho từng dịch vụ AWS
-  **Well-documented**: Comments chi tiết trong mọi file
-  **Reusable**: Modules có thể tái sử dụng cho các project khác

---

##  KIẾN TRÚC HỆ THỐNG

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS CLOUD                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                        │  │
│  │                                                           │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────┐  │  │
│  │  │ Public Subnet       │    │ Private Subnet          │  │  │
│  │  │ (10.0.1.0/24)       │    │ (10.0.2.0/24)           │  │  │
│  │  │                     │    │                         │  │  │
│  │  │  ┌──────────────┐   │    │  ┌──────────────┐      │  │  │
│  │  │  │ Public EC2   │   │    │  │ Private EC2  │      │  │  │
│  │  │  │ t3.micro     │   │    │  │ t3.micro     │      │  │  │
│  │  │  │ Public IP    │   │    │  │ No Public IP │      │  │  │
│  │  │  └──────┬───────┘   │    │  └──────┬───────┘      │  │  │
│  │  │         │           │    │         │              │  │  │
│  │  │  ┌──────┴───────┐   │    │         │              │  │  │
│  │  │  │ NAT Gateway  │   │    │         │              │  │  │
│  │  │  │ EIP: x.x.x.x │   │    │         │              │  │  │
│  │  │  └──────┬───────┘   │    │         │              │  │  │
│  │  └─────────┼───────────┘    └─────────┼──────────────┘  │  │
│  │            │                           │                 │  │
│  │  ┌─────────┴───────────────────────────┴──────────┐     │  │
│  │  │         Internet Gateway                        │     │  │
│  │  └─────────┬───────────────────────────────────────┘     │  │
│  └────────────┼─────────────────────────────────────────────┘  │
│               │                                                 │
└───────────────┼─────────────────────────────────────────────────┘
                │
        ┌───────┴────────┐
        │   INTERNET     │
        │                │
        │  Your PC       │
        │  (SSH Access)  │
        └────────────────┘
```

### Luồng traffic:

1. **Internet → Public EC2:**
   - User (IP: 42.113.225.23) → Internet Gateway → Public EC2
   - Chỉ cho phép SSH (port 22) từ IP cụ thể

2. **Public EC2 → Internet:**
   - Public EC2 → Internet Gateway → Internet

3. **Public EC2 → Private EC2:**
   - Public EC2 (Bastion/Jump host) → Private EC2
   - Security Group cho phép toàn bộ traffic từ Public SG

4. **Private EC2 → Internet:**
   - Private EC2 → NAT Gateway → Internet Gateway → Internet
   - Private EC2 không thể nhận kết nối từ Internet (inbound blocked)

---

##  CẤU TRÚC DỰ ÁN

```
d:\Phúc\STUDY\DevOps\LAB\LAB01\Terraform\
│
├── main.tf                          # File chính orchestrate tất cả modules
├── provider.tf                      # Cấu hình AWS Provider
├── variables.tf                     # Khai báo variables (inputs)
├── terraform.tfvars                 # Giá trị cụ thể cho variables ⚠️ SENSITIVE
├── outputs.tf                       # Outputs (VPC ID, EC2 IPs, etc.)
├── .gitignore                       # Ignore sensitive files
│
├── modules/                         # 7 MODULES CHÍNH
│   ├── vpc/                         # Module 1: VPC
│   │   ├── main.tf                  # Tạo VPC với DNS support
│   │   ├── variables.tf             # VPC inputs (CIDR, tags)
│   │   └── outputs.tf               # VPC ID, CIDR
│   │
│   ├── subnet/                      # Module 2: Subnet (reusable)
│   │   ├── main.tf                  # Tạo subnet (public/private)
│   │   ├── variables.tf             # Subnet configs
│   │   └── outputs.tf               # Subnet ID
│   │
│   ├── internet_gateway/            # Module 3: Internet Gateway
│   │   ├── main.tf                  # Tạo IGW và attach vào VPC
│   │   ├── variables.tf             # IGW configs
│   │   └── outputs.tf               # IGW ID
│   │
│   ├── nat_gateway/                 # Module 4: NAT Gateway
│   │   ├── main.tf                  # Tạo NAT + Elastic IP
│   │   ├── variables.tf             # NAT configs
│   │   └── outputs.tf               # NAT ID, EIP
│   │
│   ├── route_table/                 # Module 5: Route Table (reusable)
│   │   ├── main.tf                  # Tạo RT với conditional routing
│   │   ├── variables.tf             # RT configs (IGW/NAT)
│   │   └── outputs.tf               # RT ID
│   │
│   ├── security_group/              # Module 6: Security Group (reusable)
│   │   ├── main.tf                  # Tạo SG với conditional rules
│   │   ├── variables.tf             # SG configs
│   │   └── outputs.tf               # SG ID
│   │
│   └── ec2/                         # Module 7: EC2 Instance (reusable)
│       ├── main.tf                  # Tạo EC2 với user_data
│       ├── variables.tf             # EC2 configs
│       ├── outputs.tf               # Instance ID, IPs
│       ├── user_data_public.sh      # Bootstrap script cho Public EC2
│       └── user_data_private.sh     # Bootstrap script cho Private EC2
│
├── tests/                           # TEST SUITE
│   ├── test-services.ps1            # Main test script (19 tests, 8 services)
│   ├── README-TESTS.md              # Test documentation
│   └── test.sh                      # Bash test script (for Linux)
│
├── working-key.pem                  # SSH private key 
│
├── ssh-connect.ps1                  # Helper script: SSH to Public EC2
├── copy-key-and-connect.ps1         # Helper script: Copy key + SSH
│
├── README.md                        # Documentation (file này)
├── DEPLOYMENT_GUIDE.md              # Step-by-step deployment guide
├── PROJECT_SUMMARY.md               # Project overview
└── CLEANUP-SUMMARY.md               # Cleanup và test summary

TỔNG CỘNG: 
- 7 Modules
- 28 Files Terraform (.tf)
- 19 Test cases
- 4 Helper scripts
- 5 Documentation files
```

---

##  YÊU CẦU HỆ THỐNG

### Phần mềm bắt buộc:

| Software | Version | Download | Mục đích |
|----------|---------|----------|----------|
| **Terraform** | >= 1.6.0 | https://www.terraform.io/downloads | Infrastructure as Code tool |
| **AWS CLI** | >= 2.x | https://aws.amazon.com/cli/ | Interact với AWS services |
| **PowerShell** | >= 5.1 | Built-in Windows | Chạy scripts và commands |
| **SSH Client** | OpenSSH | Built-in Windows 10+ | Kết nối EC2 instances |

### Tài khoản AWS:

-  AWS Account (Free Tier eligible)
-  IAM User với permissions:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*"
    }]
  }
  ```
-  AWS Access Key ID và Secret Access Key

### Kiểm tra cài đặt:

```powershell
# Check Terraform
terraform version
# Output: Terraform v1.6.0 (hoặc cao hơn)

# Check AWS CLI
aws --version
# Output: aws-cli/2.x.x

# Check SSH
ssh -V
# Output: OpenSSH_for_Windows_8.x

# Check PowerShell
$PSVersionTable.PSVersion
# Output: 5.1.x hoặc 7.x
```

---

##  CÀI ĐẶT VÀ CẤU HÌNH

### BƯỚC 1: Clone hoặc Download project

```powershell
# Nếu có Git
git clone <repository-url>
cd Terraform

# Hoặc download ZIP và extract
cd "d:\Phúc\STUDY\DevOps\LAB\LAB01\Terraform"
```

### BƯỚC 2: Cấu hình AWS Credentials

**Cách 1: Sử dụng file `terraform.tfvars` (Đang dùng)**

File `terraform.tfvars` đã chứa credentials:
```hcl
aws_access_key = "YOUR_AWS_ACCESS_KEY_HERE"
aws_secret_key = "YOUR_AWS_SECRET_KEY_HERE"
aws_region     = "ap-southeast-1"
```

**Cách 2: Sử dụng AWS CLI (Khuyến nghị cho production)**

```powershell
aws configure
# AWS Access Key ID: YOUR_AWS_ACCESS_KEY_HERE
# AWS Secret Access Key: YOUR_AWS_SECRET_KEY_HERE
# Default region name: ap-southeast-1
# Default output format: json
```

### BƯỚC 3: Tạo SSH Key Pair trên AWS

```powershell
# Tạo key pair trên AWS Console hoặc CLI
aws ec2 create-key-pair `
  --key-name nt548-lab01-key `
  --region ap-southeast-1 `
  --query 'KeyMaterial' `
  --output text | Out-File -FilePath working-key.pem -Encoding ASCII

# Set permissions (Windows)
icacls working-key.pem /inheritance:r
icacls working-key.pem /grant:r "$($env:USERNAME):(R)"
```

 **QUAN TRỌNG:** 
- Key pair name trong AWS: `nt548-lab01-key`
- Local file: `working-key.pem`
- Đã có sẵn trong project, KHÔNG cần tạo lại nếu đã có

### BƯỚC 4: Cấu hình IP của bạn

```powershell
# Lấy IP hiện tại
$MY_IP = Invoke-RestMethod https://api.ipify.org
Write-Host "Your IP: $MY_IP"

# Mở terraform.tfvars và update dòng:
my_ip = "42.113.225.23/32"  # Thay bằng IP của bạn
```

**Lý do:** Security Group chỉ cho phép SSH từ IP này (yêu cầu đề bài 2 điểm!)

---

##  HƯỚNG DẪN TRIỂN KHAI

### PHƯƠNG PHÁP 1: Manual (Step-by-step)

#### Bước 1: Khởi tạo Terraform

```powershell
cd "d:\Phúc\STUDY\DevOps\LAB\LAB01\Terraform"

# Initialize Terraform (download providers, modules)
terraform init
```

**Kết quả mong đợi:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.100.0...

Terraform has been successfully initialized!
```

#### Bước 2: Validate cấu hình

```powershell
# Kiểm tra syntax
terraform validate
```

**Kết quả mong đợi:**
```
Success! The configuration is valid.
```

#### Bước 3: Xem kế hoạch triển khai

```powershell
# Xem chi tiết những gì sẽ được tạo
terraform plan
```

**Kết quả:** Hiển thị 25 resources sẽ được tạo:
- 1 VPC
- 2 Subnets (Public + Private)
- 1 Internet Gateway
- 1 NAT Gateway + 1 Elastic IP
- 2 Route Tables + 2 Associations + 2 Routes
- 3 Security Groups (default + public + private)
- 5 Security Group Rules
- 2 EC2 Instances

#### Bước 4: Apply (Triển khai)

```powershell
# Triển khai infrastructure
terraform apply

# Terraform sẽ hỏi confirm, gõ: yes
```

 **Thời gian:** ~3-5 phút (NAT Gateway mất 1-2 phút)

**Kết quả mong đợi:**
```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

internet_gateway_id = "igw-02fc35c6e21076730"
nat_gateway_id = "nat-0ad10bd4b0a9597fc"
nat_gateway_public_ip = "122.248.211.51"
private_ec2_id = "i-084c1f1ed7271506a"
private_ec2_private_ip = "10.0.2.46"
public_ec2_id = "i-0809de110fee9af76"
public_ec2_public_ip = "47.129.241.42"
vpc_id = "vpc-08fa667fbb60fcf1e"
```

#### Bước 5: Xem Outputs

```powershell
# Xem tất cả outputs
terraform output

# Xem specific output
terraform output public_ec2_public_ip
terraform output private_ec2_private_ip
terraform output nat_gateway_public_ip
```

---

##  KIỂM THỬ HỆ THỐNG

### Test Suite Tự động

Project có test suite tự động với **19 test cases** cho **8 dịch vụ AWS**:

#### Chạy full test suite:

```powershell
.\tests\test-services.ps1
```

#### Kết quả mong đợi:

```
========================================================
  NT548 LAB 01 - SERVICE TEST SUITE
  Test tung dich vu AWS duoc trien khai
========================================================

================================================
 TEST 1: VPC SERVICE
================================================
  [PASS] VPC created: vpc-08fa667fbb60fcf1e
  [PASS] VPC CIDR correct: 10.0.0.0/16

================================================
 TEST 2: SUBNET SERVICE
================================================
  [PASS] Public Subnet: subnet-0b1c13027a54d1323
  [PASS] Private Subnet: subnet-0e5d66d0fef4f81e8

[... 17 more tests ...]

========================================================
 TEST SUMMARY
========================================================

  PASSED:  19
  FAILED:  0
  SKIPPED: 0
  TOTAL:   19

Results by Service:
  - VPC: 2/2 passed
  - Subnet: 2/2 passed
  - IGW: 1/1 passed
  - NAT: 2/2 passed
  - Route Table: 2/2 passed
  - Security Group: 3/3 passed
  - EC2: 6/6 passed
  - Connectivity: 1/1 passed

SUCCESS: All services working!
```

### Test Cases chi tiết:

| # | Service | Test Case | Mục đích |
|---|---------|-----------|----------|
| 1-2 | **VPC** | VPC creation, CIDR verification | Kiểm tra VPC với CIDR 10.0.0.0/16 |
| 3-4 | **Subnet** | Public & Private subnet | Kiểm tra 2 subnets với đúng CIDR |
| 5 | **IGW** | Internet Gateway | Verify IGW attached vào VPC |
| 6-7 | **NAT** | NAT Gateway + EIP | Verify NAT và Elastic IP |
| 8-9 | **Route Table** | Public & Private RT | Verify routes (IGW/NAT) |
| 10-12 | **Security Group** | Public SG, Private SG, SSH rule | **Verify SSH chỉ từ IP cụ thể (2 điểm!)** |
| 13-18 | **EC2** | Instances, IPs, State | Verify 2 EC2, Public IP, **NO Private Public IP** |
| 19 | **Connectivity** | SSH test | Test SSH connection thực tế |

 **Tài liệu test:** Xem chi tiết trong `tests/README-TESTS.md`

---

##  KẾT NỐI SSH

### SSH vào Public EC2:

```powershell
# Cách 1: Manual
ssh -i working-key.pem ubuntu@47.129.241.42

# Cách 2: Sử dụng helper script
.\ssh-connect.ps1
```

**Output khi thành công:**
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-1012-aws x86_64)

======================================
  Welcome to Public EC2 Instance
  NT548 Lab 01 - Terraform Demo
======================================

ubuntu@ip-10-0-1-96:~$
```

### SSH vào Private EC2 (từ Public EC2):

```powershell
# Bước 1: Copy key vào Public EC2
scp -i working-key.pem working-key.pem ubuntu@47.129.241.42:/home/ubuntu/key.pem

# Bước 2: SSH vào Public EC2
ssh -i working-key.pem ubuntu@47.129.241.42

# Bước 3: Từ Public EC2, SSH vào Private
chmod 400 key.pem
ssh -i key.pem ubuntu@10.0.2.46
```

**Helper script (tự động):**
```powershell
.\copy-key-and-connect.ps1
```

### Test kết nối:

```bash
# Từ Public EC2: Test Internet qua IGW
ping -c 4 8.8.8.8
curl https://google.com

# Từ Private EC2: Test Internet qua NAT
ping -c 4 8.8.8.8
curl http://checkip.amazonaws.com  # Should show NAT IP: 122.248.211.51

# Từ Public EC2: Ping Private EC2
ping -c 4 10.0.2.46
```

---

##  CHI TIẾT MODULES

### Module 1: VPC

**File:** `modules/vpc/main.tf`

**Chức năng:**
- Tạo Virtual Private Cloud
- Enable DNS hostnames và DNS support
- Tạo default security group

**Inputs:**
```hcl
vpc_cidr     = "10.0.0.0/16"  # 65,536 IPs
project_name = "nt548-lab01"
environment  = "dev"
```

**Outputs:**
```hcl
vpc_id   = "vpc-xxxxxxxx"
vpc_cidr = "10.0.0.0/16"
```

---

### Module 2: Subnet (Reusable)

**File:** `modules/subnet/main.tf`

**Chức năng:**
- Tạo subnet (Public hoặc Private)
- Conditional: `map_public_ip_on_launch` nếu là public

**Inputs:**
```hcl
vpc_id            = module.vpc.vpc_id
cidr_block        = "10.0.1.0/24"  # 256 IPs
availability_zone = "ap-southeast-1a"
is_public         = true/false
```

**Sử dụng:**
- Public Subnet: `is_public = true` → auto-assign public IP
- Private Subnet: `is_public = false` → no public IP

---

### Module 3: Internet Gateway

**File:** `modules/internet_gateway/main.tf`

**Chức năng:**
- Tạo IGW
- Attach vào VPC

**Mục đích:** Cho phép Public Subnet kết nối Internet

---

### Module 4: NAT Gateway

**File:** `modules/nat_gateway/main.tf`

**Chức năng:**
- Tạo Elastic IP
- Tạo NAT Gateway trong Public Subnet
- Associate EIP với NAT

**Chi phí:** ~$0.045/giờ = ~$32/tháng

**Mục đích:** Cho phép Private Subnet ra Internet (outbound only)

---

### Module 5: Route Table (Reusable)

**File:** `modules/route_table/main.tf`

**Chức năng:**
- Tạo Route Table
- Add route conditional:
  - Public RT: `0.0.0.0/0 → igw-xxx`
  - Private RT: `0.0.0.0/0 → nat-xxx`
- Associate với subnet

---

### Module 6: Security Group (Reusable)

**File:** `modules/security_group/main.tf`

**Chức năng:**
- Tạo Security Group
- Add rules conditional:

**Public SG Rules:**
```hcl
Inbound:
  - SSH (22)   from 42.113.225.23/32 
  - HTTP (80)  from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0

Outbound:
  - All traffic to 0.0.0.0/0
```

**Private SG Rules:**
```hcl
Inbound:
  - SSH (22)        from Public SG 
  - All TCP (0-65535) from Public SG
  - ICMP            from Public SG (ping)

Outbound:
  - All traffic to 0.0.0.0/0
```

---

### Module 7: EC2 (Reusable)

**File:** `modules/ec2/main.tf`

**Chức năng:**
- Tạo EC2 instance
- Attach Security Group
- Run user_data script bootstrap
- Create EBS volume (8GB, gp3, encrypted)

**User Data Scripts:**

**Public EC2 (`user_data_public.sh`):**
```bash
#!/bin/bash
# Update system
apt-get update -y

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Install AWS CLI
apt-get install -y awscli

# Install tools
apt-get install -y htop vim git wget curl

# Create welcome banner
cat > /etc/update-motd.d/99-custom << 'EOF'
======================================
  Welcome to Public EC2 Instance
  NT548 Lab 01 - Terraform Demo
======================================
EOF
chmod +x /etc/update-motd.d/99-custom
```

**Private EC2 (`user_data_private.sh`):**
- Tương tự Public nhưng có banner khác

---

##  TROUBLESHOOTING

### Vấn đề 1: Terraform init fail

**Lỗi:**
```
Error: Failed to query available provider packages
```

**Giải pháp:**
```powershell
# Delete lock file
Remove-Item .terraform.lock.hcl

# Re-init
terraform init
```

---

### Vấn đề 2: SSH Connection timeout

**Nguyên nhân:** IP của bạn thay đổi

**Giải pháp:**
```powershell
# Check IP hiện tại
Invoke-RestMethod https://api.ipify.org

# Update terraform.tfvars
my_ip = "<new-ip>/32"

# Re-apply
terraform apply -auto-approve
```

---

### Vấn đề 3: Cannot SSH vào Private EC2

**Nguyên nhân:** Key chưa copy vào Public EC2

**Giải pháp:**
```powershell
# Copy key
scp -i working-key.pem working-key.pem ubuntu@<public-ip>:/home/ubuntu/key.pem

# SSH vào Public, rồi SSH vào Private
ssh -i working-key.pem ubuntu@<public-ip>
chmod 400 key.pem
ssh -i key.pem ubuntu@10.0.2.46
```

---

### Vấn đề 4: NAT Gateway quá đắt

**Chi phí:** ~$32/tháng

**Giải pháp tạm thời:**
```powershell
# Comment out NAT trong main.tf (test only)
# Sau khi test xong:
terraform destroy
```

---

### Vấn đề 5: Terraform state locked

**Lỗi:**
```
Error: Error acquiring the state lock
```

**Giải pháp:**
```powershell
# Force unlock (nguy hiểm!)
terraform force-unlock <lock-id>
```

---

##  OUTPUTS REFERENCE

Sau khi `terraform apply` thành công, các outputs:

| Output | Ví dụ | Mục đích |
|--------|-------|----------|
| `vpc_id` | vpc-08fa667fbb60fcf1e | VPC identifier |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block |
| `public_subnet_id` | subnet-0b1c13027a54d1323 | Public Subnet ID |
| `private_subnet_id` | subnet-0e5d66d0fef4f81e8 | Private Subnet ID |
| `internet_gateway_id` | igw-02fc35c6e21076730 | IGW ID |
| `nat_gateway_id` | nat-0ad10bd4b0a9597fc | NAT Gateway ID |
| `nat_gateway_public_ip` | 122.248.211.51 | NAT Elastic IP |
| `public_route_table_id` | rtb-0d7a73b830c9d616c | Public RT ID |
| `private_route_table_id` | rtb-09d8a590ebe8b4742 | Private RT ID |
| `public_security_group_id` | sg-0e9729307d103c372 | Public SG ID |
| `private_security_group_id` | sg-0e7a24649052fbb99 | Private SG ID |
| `public_ec2_id` | i-0809de110fee9af76 | Public EC2 Instance ID |
| `public_ec2_public_ip` | 47.129.241.42 | Public EC2 Public IP |
| `public_ec2_private_ip` | 10.0.1.96 | Public EC2 Private IP |
| `private_ec2_id` | i-084c1f1ed7271506a | Private EC2 Instance ID |
| `private_ec2_private_ip` | 10.0.2.46 | Private EC2 Private IP |

---

##  CHI PHÍ DỰ KIẾN

| Service | Chi phí | Ghi chú |
|---------|---------|---------|
| **VPC** | $0 | Free |
| **Subnet** | $0 | Free |
| **Internet Gateway** | $0 | Free |
| **NAT Gateway** | ~$32/tháng | $0.045/giờ |
| **Elastic IP** | $0 | Free (khi attach vào NAT) |
| **EC2 t3.micro** x2 | $0 | Free Tier: 750 giờ/tháng |
| **EBS gp3 8GB** x2 | $0 | Free Tier: 30GB/tháng |
| **Data Transfer** | $0 | Free Tier: 100GB/tháng |

** TỔNG:** ~$32/tháng (chỉ NAT Gateway)

** Tiết kiệm:** Destroy infrastructure sau khi test xong!

---

##  XÓA HẠ TẦNG

### Cách 1: Terraform destroy

```powershell
terraform destroy

# Confirm: yes
```

 **Thời gian:** ~3 phút

### Cách 2: AWS Console

Manual delete từng resource (không khuyến nghị)

###  LƯU Ý QUAN TRỌNG:

- Destroy ngay sau khi demo/test
- NAT Gateway tính phí theo giờ
- Terraform state file sẽ bị xóa
- Backup `terraform.tfstate` nếu cần

---

### Project Documentation:
- `DEPLOYMENT_GUIDE.md` - Hướng dẫn triển khai chi tiết
- `tests/README-TESTS.md` - Test cases documentation
- `PROJECT_SUMMARY.md` - Project overview
- `CLEANUP-SUMMARY.md` - Cleanup và test summary

---

##  THÔNG TIN DỰ ÁN

- **Môn học:** NT548 - DevOps
- **Lab:** Lab 01 - Infrastructure as Code with Terraform
- **Sinh viên:** Phúc
- **Công cụ:** Terraform, AWS, PowerShell
- **Thời gian:** October 2025
- **Version:** 1.0.0

---

##  CHECKLIST HOÀN THÀNH

- [x] 7 Modules Terraform (VPC, Subnet, IGW, NAT, RT, SG, EC2)
- [x] Security Groups đúng yêu cầu 
- [x] NAT Gateway cho Private Subnet
- [x] Test Suite (19 tests, 8 services)
- [x] Documentation đầy đủ
- [x] Helper scripts (SSH, deployment)
- [x] .gitignore cho sensitive files
- [x] Kiểm thử end-to-end thành công

---


##  KẾT LUẬN

Project này demonstate:
-  **Infrastructure as Code** với Terraform
-  **Modular Architecture** dễ maintain và scale
-  **Security Best Practices** (Security Groups, Private Subnet)
-  **Automated Testing** (19 test cases)
-  **Production-ready** code với documentation đầy đủ

---

