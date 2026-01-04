# NT548 LAB 01 - AWS Infrastructure with CloudFormation

## 📋 MỤC LỤC
- [Giới thiệu](#-giới-thiệu)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt và cấu hình](#-cài-đặt-và-cấu-hình)
- [Hướng dẫn triển khai](#-hướng-dẫn-triển-khai)
- [Kiểm thử hệ thống](#-kiểm-thử-hệ-thống)
- [Kết nối SSH](#-kết-nối-ssh)
- [So sánh với Terraform](#-so-sánh-với-terraform)
- [Troubleshooting](#-troubleshooting)
- [Xóa hạ tầng](#-xóa-hạ-tầng)

---

## 🎯 GIỚI THIỆU

### Mục đích
Dự án này sử dụng **AWS CloudFormation** (Infrastructure as Code) để tự động triển khai một hạ tầng AWS hoàn chỉnh, tương tự như phiên bản Terraform nhưng sử dụng native AWS tool.

### Đặc điểm nổi bật
- ✅ **Single Template**: Tất cả resources trong 1 file YAML duy nhất
- ✅ **AWS Native**: Không cần cài đặt thêm tools ngoài AWS CLI
- ✅ **Parameter-driven**: Dễ dàng customize qua parameters
- ✅ **Dependency Management**: CloudFormation tự động quản lý dependencies
- ✅ **Rollback Support**: Tự động rollback nếu có lỗi
- ✅ **Change Sets**: Preview changes trước khi apply

### Infrastructure bao gồm:
- 🌐 Virtual Private Cloud (VPC) với 2 subnets (Public & Private)
- 🌍 Internet Gateway cho Public Subnet
- 🔄 NAT Gateway cho Private Subnet ra Internet
- 🗺️ Route Tables với routing rules
- 🔒 Security Groups với firewall rules (SSH chỉ từ IP cụ thể)
- 💻 2 EC2 instances (t3.micro - Free Tier eligible)

---

## 🏗️ KIẾN TRÚC HỆ THỐNG

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
│  │  │  │ Public IP ✓  │   │    │  │ No Public IP │      │  │  │
│  │  │  └──────┬───────┘   │    │  └──────┬───────┘      │  │  │
│  │  │         │           │    │         │              │  │  │
│  │  │  ┌──────┴───────┐   │    │         │              │  │  │
│  │  │  │ NAT Gateway  │   │    │         │              │  │  │
│  │  │  │ EIP: x.x.x.x │◄──┼────┼─────────┘              │  │  │
│  │  │  └──────┬───────┘   │    │                        │  │  │
│  │  └─────────┼───────────┘    └────────────────────────┘  │  │
│  │            │                                             │  │
│  │  ┌─────────┴───────────────────────────────────────┐    │  │
│  │  │         Internet Gateway                        │    │  │
│  │  └─────────┬───────────────────────────────────────┘    │  │
│  └────────────┼──────────────────────────────────────────────┘  │
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

### Luồng Traffic:

1. **Internet → Public EC2:**
   - User (MyIP) → Internet Gateway → Public EC2
   - ⚠️ **QUAN TRỌNG**: SSH chỉ cho phép từ IP cụ thể (yêu cầu 2 điểm!)

2. **Public EC2 → Internet:**
   - Public EC2 → Internet Gateway → Internet

3. **Public EC2 → Private EC2:**
   - Public EC2 (Bastion host) → Private EC2
   - Security Group cho phép toàn bộ traffic từ Public SG

4. **Private EC2 → Internet:**
   - Private EC2 → NAT Gateway → Internet Gateway → Internet
   - ✅ Private EC2 không có Public IP (yêu cầu đề bài!)

---

## 💻 YÊU CẦU HỆ THỐNG

### Phần mềm bắt buộc:

| Software | Version | Download | Mục đích |
|----------|---------|----------|----------|
| **AWS CLI** | >= 2.x | https://aws.amazon.com/cli/ | Deploy CloudFormation stack |
| **PowerShell** | >= 5.1 | Built-in Windows | Chạy scripts |
| **SSH Client** | OpenSSH | Built-in Windows 10+ | Kết nối EC2 |

### Tài khoản AWS:

- ✅ AWS Account (Free Tier eligible)
- ✅ IAM User với permissions:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "ec2:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }]
  }
  ```
- ✅ AWS Access Key ID và Secret Access Key

### Kiểm tra cài đặt:

```powershell
# Check AWS CLI
aws --version
# Output: aws-cli/2.x.x

# Check AWS credentials
aws sts get-caller-identity
# Should return your account info

# Check SSH
ssh -V
# Output: OpenSSH_for_Windows_8.x

# Check PowerShell
$PSVersionTable.PSVersion
# Output: 5.1.x hoặc 7.x
```

---

## ⚙️ CÀI ĐẶT VÀ CẤU HÌNH

### BƯỚC 1: Cấu hình AWS Credentials

```powershell
# Configure AWS CLI
aws configure

# Input your credentials:
# AWS Access Key ID: YOUR_AWS_ACCESS_KEY_HERE
# AWS Secret Access Key: YOUR_AWS_SECRET_KEY_HERE
# Default region name: ap-southeast-1
# Default output format: json
```

### BƯỚC 2: Tạo SSH Key Pair

```powershell
# Create key pair on AWS
aws ec2 create-key-pair `
  --key-name nt548-lab01-key `
  --region ap-southeast-1 `
  --query 'KeyMaterial' `
  --output text | Out-File -FilePath working-key.pem -Encoding ASCII

# Set permissions (Windows)
icacls working-key.pem /inheritance:r
icacls working-key.pem /grant:r "$($env:USERNAME):(R)"
```

⚠️ **LƯU Ý**: Key pair name phải là `nt548-lab01-key` (đã hard-code trong template)

### BƯỚC 3: Lấy IP của bạn

```powershell
# Get your current IP
$MY_IP = Invoke-RestMethod https://api.ipify.org
Write-Host "Your IP: $MY_IP/32"
```

**GHI NHỚ IP NÀY** - Bạn sẽ cần nó khi deploy!

---

## 🚀 HƯỚNG DẪN TRIỂN KHAI

### PHƯƠNG PHÁP 1: Deploy với AWS CLI (Recommended)

#### Bước 1: Validate template

```powershell
cd "d:\Phúc\STUDY\DevOps\LAB\LAB01\CloudFormation"

# Validate CloudFormation template syntax
aws cloudformation validate-template `
  --template-body file://main.yaml `
  --region ap-southeast-1
```

**Kết quả mong đợi:**
```json
{
    "Parameters": [...],
    "Description": "NT548 LAB 01 - AWS Infrastructure with CloudFormation..."
}
```

#### Bước 2: Deploy stack

```powershell
# Deploy CloudFormation stack với parameters
aws cloudformation create-stack `
  --stack-name nt548-lab01-stack `
  --template-body file://main.yaml `
  --parameters `
    ParameterKey=MyIP,ParameterValue=42.113.225.23/32 `
    ParameterKey=ProjectName,ParameterValue=nt548-lab01 `
    ParameterKey=Environment,ParameterValue=dev `
    ParameterKey=KeyName,ParameterValue=nt548-lab01-key `
  --region ap-southeast-1 `
  --capabilities CAPABILITY_IAM

# ⚠️ QUAN TRỌNG: Thay 42.113.225.23 bằng IP của bạn!
```

**Kết quả:**
```json
{
    "StackId": "arn:aws:cloudformation:ap-southeast-1:xxxx:stack/nt548-lab01-stack/xxx"
}
```

#### Bước 3: Monitor deployment

```powershell
# Watch stack creation progress
aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].StackStatus'

# Or watch events in real-time
aws cloudformation describe-stack-events `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --max-items 10
```

**Status progression:**
```
CREATE_IN_PROGRESS → CREATE_COMPLETE (success)
                  → CREATE_FAILED     (error)
                  → ROLLBACK_COMPLETE (auto-rollback)
```

⏱️ **Thời gian**: ~3-5 phút (NAT Gateway mất nhiều thời gian nhất)

#### Bước 4: Get outputs

```powershell
# Get all stack outputs
aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs'

# Get specific output (Public EC2 IP)
aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`PublicEC2PublicIP`].OutputValue' `
  --output text
```

---

### PHƯƠNG PHÁP 2: Deploy qua AWS Console

1. **Mở AWS CloudFormation Console:**
   - https://console.aws.amazon.com/cloudformation/

2. **Create Stack:**
   - Click "Create stack" → "With new resources"
   - Upload `main.yaml` file
   - Click "Next"

3. **Specify Stack Details:**
   - Stack name: `nt548-lab01-stack`
   - Parameters:
     - MyIP: `<Your-IP>/32` (QUAN TRỌNG!)
     - ProjectName: `nt548-lab01`
     - Environment: `dev`
     - KeyName: `nt548-lab01-key`
     - Các parameters khác: giữ default
   - Click "Next"

4. **Configure Stack Options:**
   - Tags (optional): Key=Owner, Value=YourName
   - Click "Next"

5. **Review:**
   - Check "I acknowledge that AWS CloudFormation might create IAM resources"
   - Click "Submit"

6. **Monitor:**
   - Xem tab "Events" để theo dõi tiến trình
   - Chờ status = "CREATE_COMPLETE"

---

## ✅ KIỂM THỬ HỆ THỐNG

### Test 1: Verify Stack Creation

```powershell
# Check stack status
aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].StackStatus'

# Expected: "CREATE_COMPLETE"
```

### Test 2: Verify Resources

```powershell
# List all resources in stack
aws cloudformation list-stack-resources `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Expected: 22 resources created
```

### Test 3: Verify VPC

```powershell
# Get VPC ID from stack
$VPC_ID = aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' `
  --output text

# Describe VPC
aws ec2 describe-vpcs `
  --vpc-ids $VPC_ID `
  --region ap-southeast-1

# Check CIDR: Should be 10.0.0.0/16
```

### Test 4: Verify Subnets

```powershell
# List subnets in VPC
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --region ap-southeast-1 `
  --query 'Subnets[*].[SubnetId,CidrBlock,MapPublicIpOnLaunch]' `
  --output table

# Expected:
# 10.0.1.0/24 | True  (Public Subnet)
# 10.0.2.0/24 | False (Private Subnet)
```

### Test 5: Verify NAT Gateway

```powershell
# Get NAT Gateway ID
$NAT_ID = aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`NATGatewayId`].OutputValue' `
  --output text

# Describe NAT Gateway
aws ec2 describe-nat-gateways `
  --nat-gateway-ids $NAT_ID `
  --region ap-southeast-1

# Check State: Should be "available"
```

### Test 6: Verify Security Groups

```powershell
# Get Public Security Group rules
$PUBLIC_SG_ID = aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`PublicSecurityGroupId`].OutputValue' `
  --output text

aws ec2 describe-security-group-rules `
  --filters "Name=group-id,Values=$PUBLIC_SG_ID" `
  --region ap-southeast-1

# ✅ VERIFY: SSH (port 22) chỉ từ MyIP (yêu cầu 2 điểm!)
```

### Test 7: Verify EC2 Instances

```powershell
# List EC2 instances in stack
aws ec2 describe-instances `
  --filters "Name=tag:Project,Values=nt548-lab01" `
  --region ap-southeast-1 `
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress,State.Name]' `
  --output table

# Expected:
# Public EC2:  i-xxxxx | <Public-IP> | 10.0.1.x | running
# Private EC2: i-yyyyy | None        | 10.0.2.x | running
#                         ^^^^
#                         ✅ NO PUBLIC IP (yêu cầu đề bài!)
```

### Test 8: Verify SSH Access

```powershell
# Get Public EC2 IP
$PUBLIC_IP = aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`PublicEC2PublicIP`].OutputValue' `
  --output text

# SSH to Public EC2
ssh -i working-key.pem ubuntu@$PUBLIC_IP

# Expected: Login successful
```

---

## 🔐 KẾT NỐI SSH

### SSH vào Public EC2

```powershell
# Get Public IP
$PUBLIC_IP = aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --query 'Stacks[0].Outputs[?OutputKey==`PublicEC2PublicIP`].OutputValue' `
  --output text

# SSH
ssh -i working-key.pem ubuntu@$PUBLIC_IP
```

**Welcome Message:**
```
======================================
  Welcome to Public EC2 Instance
  NT548 Lab 01 - CloudFormation Demo
  Project: nt548-lab01
  Environment: dev
======================================
ubuntu@ip-10-0-1-x:~$
```

### SSH vào Private EC2 (qua Public EC2)

```powershell
# Step 1: Copy key to Public EC2
scp -i working-key.pem working-key.pem ubuntu@$PUBLIC_IP:/home/ubuntu/key.pem

# Step 2: SSH to Public EC2
ssh -i working-key.pem ubuntu@$PUBLIC_IP

# Step 3: From Public EC2, SSH to Private EC2
chmod 400 key.pem

# Get Private IP
PRIVATE_IP=$(aws cloudformation describe-stacks \
  --stack-name nt548-lab01-stack \
  --region ap-southeast-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`PrivateEC2PrivateIP`].OutputValue' \
  --output text)

ssh -i key.pem ubuntu@$PRIVATE_IP
```

### Test Connectivity

```bash
# From Public EC2: Test Internet via IGW
ping -c 4 8.8.8.8
curl https://google.com

# From Private EC2: Test Internet via NAT
ping -c 4 8.8.8.8
curl http://checkip.amazonaws.com
# Should show NAT Gateway's Elastic IP

# From Public EC2: Ping Private EC2
ping -c 4 10.0.2.x
```

---

## 🔄 SO SÁNH VỚI TERRAFORM

| Feature | CloudFormation | Terraform |
|---------|---------------|-----------|
| **Tool** | AWS Native | Third-party (HashiCorp) |
| **Language** | YAML/JSON | HCL |
| **State Management** | AWS-managed | Local/Remote (S3, etc.) |
| **Multi-cloud** | ❌ AWS only | ✅ Multi-cloud |
| **Structure** | Single template | Modular (7 modules) |
| **Learning Curve** | Lower (AWS users) | Higher |
| **Rollback** | ✅ Automatic | Manual (terraform destroy) |
| **Change Preview** | Change Sets | terraform plan |
| **Dependencies** | Auto-managed | DependsOn required |
| **Cost** | Free | Free (Open source) |
| **Community** | AWS docs | Large community |

### Khi nào dùng CloudFormation?
- ✅ Pure AWS infrastructure
- ✅ Team quen AWS
- ✅ Cần automatic rollback
- ✅ Không muốn quản lý state file

### Khi nào dùng Terraform?
- ✅ Multi-cloud deployment
- ✅ Reusable modules
- ✅ Large, complex infrastructure
- ✅ Version control for infrastructure code

---

## 🔧 TROUBLESHOOTING

### Issue 1: Stack Creation Failed

**Lỗi:**
```
CREATE_FAILED: Resource creation cancelled
```

**Giải pháp:**
```powershell
# Check events to find the cause
aws cloudformation describe-stack-events `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1 `
  --max-items 20

# Delete failed stack
aws cloudformation delete-stack `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Fix issue and re-deploy
```

---

### Issue 2: SSH Connection Refused

**Nguyên nhân:** MyIP parameter không đúng

**Giải pháp:**
```powershell
# Get your current IP
$MY_IP = Invoke-RestMethod https://api.ipify.org

# Update stack with new IP
aws cloudformation update-stack `
  --stack-name nt548-lab01-stack `
  --template-body file://main.yaml `
  --parameters `
    ParameterKey=MyIP,ParameterValue=$MY_IP/32 `
    ParameterKey=ProjectName,UsePreviousValue=true `
    ParameterKey=Environment,UsePreviousValue=true `
    ParameterKey=KeyName,UsePreviousValue=true `
  --region ap-southeast-1
```

---

### Issue 3: Key Pair Not Found

**Lỗi:**
```
The key pair 'nt548-lab01-key' does not exist
```

**Giải pháp:**
```powershell
# Create key pair
aws ec2 create-key-pair `
  --key-name nt548-lab01-key `
  --region ap-southeast-1 `
  --query 'KeyMaterial' `
  --output text | Out-File -FilePath working-key.pem -Encoding ASCII

# Set permissions
icacls working-key.pem /inheritance:r
icacls working-key.pem /grant:r "$($env:USERNAME):(R)"
```

---

### Issue 4: NAT Gateway Quá Đắt

**Chi phí:** ~$32/tháng

**Giải pháp:**
```powershell
# Delete stack sau khi test
aws cloudformation delete-stack `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1
```

---

### Issue 5: Cannot Update Stack

**Lỗi:**
```
Stack is in UPDATE_ROLLBACK_COMPLETE state
```

**Giải pháp:**
```powershell
# Delete and recreate
aws cloudformation delete-stack `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Wait for deletion
aws cloudformation wait stack-delete-complete `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Recreate stack
aws cloudformation create-stack ...
```

---

## 🗑️ XÓA HẠ TẦNG

### Cách 1: AWS CLI (Recommended)

```powershell
# Delete stack
aws cloudformation delete-stack `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1

# Verify deletion
aws cloudformation describe-stacks `
  --stack-name nt548-lab01-stack `
  --region ap-southeast-1
# Expected: Stack not found
```

⏱️ **Thời gian:** ~3-5 phút

### Cách 2: AWS Console

1. Mở CloudFormation Console
2. Select stack `nt548-lab01-stack`
3. Click "Delete"
4. Confirm deletion

### ⚠️ LƯU Ý QUAN TRỌNG:

- ✅ CloudFormation tự động xóa TOÀN BỘ resources
- ✅ Không cần xóa từng resource manually
- ✅ Nếu có lỗi, stack sẽ ở trạng thái DELETE_FAILED
- ❌ NAT Gateway tính phí theo giờ - xóa ngay sau khi demo!

---

## 📊 CHI PHÍ DỰ KIẾN

| Service | Chi phí | Ghi chú |
|---------|---------|---------|
| **VPC** | $0 | Free |
| **Subnets** | $0 | Free |
| **Internet Gateway** | $0 | Free |
| **NAT Gateway** | ~$32/tháng | $0.045/giờ |
| **Elastic IP** | $0 | Free (attached to NAT) |
| **EC2 t3.micro** x2 | $0 | Free Tier: 750 giờ/tháng |
| **EBS gp3 8GB** x2 | $0 | Free Tier: 30GB/tháng |
| **Data Transfer** | $0 | Free Tier: 100GB/tháng |

**💰 TỔNG:** ~$32/tháng (chỉ NAT Gateway)

**💡 TIẾT KIỆM:** Delete stack ngay sau khi test!

---

## 📁 CẤU TRÚC DỰ ÁN

```
CloudFormation/
├── main.yaml                     # Main CloudFormation template (all-in-one)
├── parameters.json               # Parameters file for AWS CLI deployment
├── deploy.ps1                    # Automated deployment script
├── delete.ps1                    # Automated cleanup script
├── test-stack.ps1                # Testing script
├── ssh-connect.ps1               # SSH helper script
├── README.md                     # Documentation (this file)
└── working-key.pem              # SSH private key (⚠️ SENSITIVE - DO NOT COMMIT)
```

---

## 📚 TÀI LIỆU THAM KHẢO

### AWS CloudFormation:
- **User Guide**: https://docs.aws.amazon.com/cloudformation/
- **Template Reference**: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html
- **Resource Types**: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html

### AWS Services:
- **VPC**: https://docs.aws.amazon.com/vpc/
- **EC2**: https://docs.aws.amazon.com/ec2/
- **NAT Gateway**: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html

---

## ✅ CHECKLIST HOÀN THÀNH

- [x] VPC với DNS support
- [x] 2 Subnets (Public có auto-assign Public IP, Private không có)
- [x] Internet Gateway cho Public Subnet
- [x] NAT Gateway + Elastic IP cho Private Subnet
- [x] Route Tables đúng (Public → IGW, Private → NAT)
- [x] Security Groups đúng yêu cầu (SSH chỉ từ IP cụ thể) ⭐ 2 ĐIỂM
- [x] 2 EC2 instances (t3.micro, Ubuntu 24.04)
- [x] Private EC2 KHÔNG có Public IP ⭐ YÊU CẦU ĐỀ BÀI
- [x] User Data scripts với welcome banners
- [x] EBS volumes encrypted
- [x] Outputs đầy đủ
- [x] Documentation đầy đủ
- [x] Deployment scripts

---

## 🎓 THÔNG TIN DỰ ÁN

- **Môn học:** NT548 - DevOps
- **Lab:** Lab 01 - Infrastructure as Code with CloudFormation
- **Công cụ:** AWS CloudFormation, AWS CLI, PowerShell
- **Region:** ap-southeast-1 (Singapore)
- **Thời gian:** October 2025

---

## 🎯 KẾT LUẬN

Project này demonstrate:
- ✅ **Infrastructure as Code** với AWS CloudFormation
- ✅ **AWS Native Tool** - không cần third-party
- ✅ **Single Template** - dễ deploy và maintain
- ✅ **Security Best Practices** - Security Groups, Private Subnet
- ✅ **Production-ready** - với automatic rollback
- ✅ **Well-documented** - hướng dẫn đầy đủ

**So với Terraform:**
- ➕ Đơn giản hơn cho AWS-only infrastructure
- ➕ Automatic dependency management
- ➕ Built-in rollback support
- ➖ Không support multi-cloud
- ➖ Ít modular hơn

---

**🚀 Happy Deploying!**
