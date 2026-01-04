# NT548 LAB01 - CloudFormation Standalone Modules

##  Architecture Overview

**Module-based infrastructure deployment WITHOUT S3 dependency**

Each service is implemented as a **standalone CloudFormation module** with:
-  1 YAML file (infrastructure definition)
-  1 PowerShell script (deployment automation)
-  Independent stack (no nested stacks, no S3)

##  Structure

```
CloudFormation/
└── standalone-modules/
    ├── vpc/
    │   ├── vpc.yaml              # VPC infrastructure definition
    │   └── deploy-vpc.ps1        # VPC deployment script
    ├── network/
    │   ├── network.yaml          # Network (Subnets, IGW, NAT, Routes)
    │   └── deploy-network.ps1    # Network deployment script
    ├── security/
    │   ├── security.yaml         # Security Groups
    │   └── deploy-security.ps1   # Security deployment script
    └── ec2/
        ├── ec2.yaml              # EC2 Instances
        └── deploy-ec2.ps1        # EC2 deployment script
```

##  Quick Start

### Option 1: Deploy All Modules at Once

```powershell
# Deploy all 4 modules in sequence
.\deploy-all-modules.ps1

# This will create 4 CloudFormation stacks:
# - nt548-lab01-vpc
# - nt548-lab01-network
# - nt548-lab01-security
# - nt548-lab01-ec2
```

### Option 2: Deploy Modules Individually

```powershell
# 1. Deploy VPC module
.\standalone-modules\vpc\deploy-vpc.ps1

# 2. Deploy Network module (requires VPC)
.\standalone-modules\network\deploy-network.ps1

# 3. Deploy Security module (requires VPC)
.\standalone-modules\security\deploy-security.ps1

# 4. Deploy EC2 module (requires all previous modules)
.\standalone-modules\ec2\deploy-ec2.ps1
```

##  Module Dependencies

```
VPC Module (no dependencies)
    ↓
    ├──→ Network Module (depends on VPC exports)
    └──→ Security Module (depends on VPC exports)
            ↓
            EC2 Module (depends on Network + Security exports)
```

##  Module Details

### Module 1: VPC
- **File**: `standalone-modules/vpc/vpc.yaml`
- **Script**: `standalone-modules/vpc/deploy-vpc.ps1`
- **Resources**: 1 VPC with DNS support
- **Exports**: VpcId, VpcCidr
- **Stack Name**: `nt548-lab01-vpc`

### Module 2: Network
- **File**: `standalone-modules/network/network.yaml`
- **Script**: `standalone-modules/network/deploy-network.ps1`
- **Resources**: 
  - 2 Subnets (Public + Private)
  - 1 Internet Gateway
  - 1 NAT Gateway
  - 1 Elastic IP
  - 2 Route Tables
- **Exports**: SubnetIds, IGW, NAT Gateway
- **Stack Name**: `nt548-lab01-network`
- **Dependencies**: VPC Module

### Module 3: Security
- **File**: `standalone-modules/security/security.yaml`
- **Script**: `standalone-modules/security/deploy-security.ps1`
- **Resources**: 
  - Public Security Group (SSH from your IP, HTTP from anywhere)
  - Private Security Group (SSH from public SG only)
- **Exports**: Security Group IDs
- **Stack Name**: `nt548-lab01-security`
- **Dependencies**: VPC Module

### Module 4: EC2
- **File**: `standalone-modules/ec2/ec2.yaml`
- **Script**: `standalone-modules/ec2/deploy-ec2.ps1`
- **Resources**: 
  - Public EC2 Instance (Bastion)
  - Private EC2 Instance
  - Both with Apache web server
- **Outputs**: Instance IDs, IPs, SSH commands, Web URL
- **Stack Name**: `nt548-lab01-ec2`
- **Dependencies**: VPC, Network, Security Modules

##  Verification

### Check All Stacks

```powershell
# List all deployed stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region ap-southeast-1 | Select-String "nt548-lab01"

# Expected output: 4 stacks
# - nt548-lab01-vpc
# - nt548-lab01-network
# - nt548-lab01-security
# - nt548-lab01-ec2
```

### Get Stack Outputs

```powershell
# VPC outputs
aws cloudformation describe-stacks --stack-name nt548-lab01-vpc --query 'Stacks[0].Outputs'

# EC2 outputs (includes SSH commands and web URL)
aws cloudformation describe-stacks --stack-name nt548-lab01-ec2 --query 'Stacks[0].Outputs'
```

### Test Infrastructure

```powershell
# 1. Get public IP from EC2 stack outputs
# 2. Open browser: http://<PUBLIC_IP>
# 3. SSH to public instance: ssh -i working-key.pem ubuntu@<PUBLIC_IP>
# 4. From bastion, SSH to private: ssh ubuntu@<PRIVATE_IP>
```

##  Cleanup

```powershell
# Delete all modules (reverse order)
.\delete-all-modules.ps1

# This will delete stacks in order:
# 1. EC2 Module
# 2. Security Module
# 3. Network Module
# 4. VPC Module
```

##  Key Features

###  Module Architecture
- **4 separate modules**, each with own YAML + script
- **Standalone CloudFormation stacks** (no nested stacks)
- **NO S3 required** (no template storage needed)
- **Clean separation of concerns**

###  Cross-Module Communication
- Uses **CloudFormation Exports/Imports**
- VPC exports `VpcId` → Network/Security import it
- Network exports `SubnetIds` → EC2 imports them
- Security exports `SecurityGroupIds` → EC2 imports them

###  Deployment Automation
- Each module has dedicated deployment script
- Scripts check dependencies before deploying
- Master script deploys all modules in sequence
- Proper error handling and validation

###  Production-Ready
- Follows AWS best practices
- Proper tagging (Project, Environment, Module)
- Security hardening (SSH from specific IP only)
- NAT Gateway for private subnet internet access
- User data scripts for automated software installation

##  Screenshots for Report

Take screenshots showing:

1. **CloudFormation Console - Stacks List**
   - Show 4 separate stacks with CREATE_COMPLETE status

2. **VPC Stack - Outputs Tab**
   - Show VpcId and exports

3. **Network Stack - Resources Tab**
   - Show Subnets, IGW, NAT Gateway, Route Tables

4. **Security Stack - Resources Tab**
   - Show 2 Security Groups

5. **EC2 Stack - Outputs Tab**
   - Show instance IDs, IPs, SSH commands

6. **EC2 Console**
   - Show 2 EC2 instances running

7. **Web Browser**
   - Show Apache homepage from public instance

8. **Module Files**
   - Show folder structure with YAML + Script pairs

##  Report Content Suggestions

### Section: Module Architecture

```markdown
## 3. CloudFormation Module Architecture

### 3.1 Implementation Approach

Yêu cầu: "Các dịch vụ phải được viết dưới dạng module"

Solution: **Standalone CloudFormation Modules**
- Mỗi module = 1 file YAML (definition) + 1 file script (deployment)
- 4 modules độc lập: VPC, Network, Security, EC2
- Module communication qua CloudFormation Exports/Imports
- KHÔNG cần S3 (standalone stacks, not nested stacks)

### 3.2 Module Details

**Module 1: VPC** (`standalone-modules/vpc/`)
- File: vpc.yaml (54 lines)
- Script: deploy-vpc.ps1 (109 lines)
- Stack: nt548-lab01-vpc
- Resources: 1 VPC
- Exports: VpcId, VpcCidr

**Module 2: Network** (`standalone-modules/network/`)
- File: network.yaml (160 lines)
- Script: deploy-network.ps1 (120 lines)
- Stack: nt548-lab01-network
- Resources: 2 Subnets, IGW, NAT, Routes
- Imports: VpcId from VPC module
- Exports: SubnetIds, Gateway IDs

**Module 3: Security** (`standalone-modules/security/`)
- File: security.yaml (85 lines)
- Script: deploy-security.ps1 (118 lines)
- Stack: nt548-lab01-security
- Resources: 2 Security Groups
- Imports: VpcId from VPC module
- Exports: Security Group IDs

**Module 4: EC2** (`standalone-modules/ec2/`)
- File: ec2.yaml (215 lines)
- Script: deploy-ec2.ps1 (155 lines)
- Stack: nt548-lab01-ec2
- Resources: 2 EC2 instances
- Imports: SubnetIds, SecurityGroupIds from previous modules
- Outputs: IPs, SSH commands, Web URL

### 3.3 Deployment Process

[Insert: Diagram showing 4 modules with dependencies]

Deployment command:
```powershell
.\deploy-all-modules.ps1
```

Result: 4 CloudFormation stacks created in sequence

### 3.4 Advantages

1. **True Module Separation**: Physical file separation per module
2. **No S3 Dependency**: Simpler than nested stacks
3. **Independent Management**: Update/delete modules individually
4. **Clear Dependencies**: Explicit import/export relationships
5. **Reusability**: Each module can be reused in other projects
```

##  Satisfies Requirements

 **"Các dịch vụ phải được viết dưới dạng module"**
- Each service (VPC, Network, Security, EC2) = separate module
- Each module has dedicated YAML file
- Each module has dedicated deployment script
- Files are physically separated in different folders

 **Module Communication**
- Uses CloudFormation Exports/Imports
- Clear dependency chain
- No hardcoded values

 **Professional Approach**
- Production-ready architecture
- Follows AWS best practices
- Automated deployment
- Proper error handling

---

