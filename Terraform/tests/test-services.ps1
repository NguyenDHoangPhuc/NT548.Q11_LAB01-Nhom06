<#
.SYNOPSIS
    Complete Test Suite for NT548 Lab 01
.DESCRIPTION
    Test tung dich vu AWS duoc trien khai
#>

$ErrorActionPreference = "SilentlyContinue"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB 01 - SERVICE TEST SUITE" -ForegroundColor Cyan
Write-Host "  Test tung dich vu AWS duoc trien khai" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$tests = @()
$region = "ap-southeast-1"

function Add-Test {
    param($Category, $Name, $Status, $Detail)
    $script:tests += @{Cat=$Category; Name=$Name; Status=$Status; Detail=$Detail}
}

function Show-Test {
    param($Status, $Msg)
    $c = if ($Status -eq "PASS") { "Green" } else { "Red" }
    $s = if ($Status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
    Write-Host "  $s $Msg" -ForegroundColor $c
}

# TEST 1: VPC
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 1: VPC SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$vpc_id = terraform output -raw vpc_id 2>$null
if ($vpc_id) {
    Show-Test "PASS" "VPC created: $vpc_id"
    Add-Test "VPC" "VPC Creation" "PASS" $vpc_id
    
    $vpc = aws ec2 describe-vpcs --vpc-ids $vpc_id --region $region --output json 2>$null | ConvertFrom-Json
    if ($vpc.Vpcs[0].CidrBlock -eq "10.0.0.0/16") {
        Show-Test "PASS" "VPC CIDR correct: 10.0.0.0/16"
        Add-Test "VPC" "VPC CIDR" "PASS" "10.0.0.0/16"
    }
} else {
    Show-Test "FAIL" "VPC not found"
    Add-Test "VPC" "VPC Creation" "FAIL" "Not found"
}

# TEST 2: SUBNETS
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 2: SUBNET SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$pub_subnet = terraform output -raw public_subnet_id 2>$null
$priv_subnet = terraform output -raw private_subnet_id 2>$null

if ($pub_subnet) {
    Show-Test "PASS" "Public Subnet: $pub_subnet"
    Add-Test "Subnet" "Public Subnet" "PASS" $pub_subnet
} else {
    Show-Test "FAIL" "Public Subnet not found"
    Add-Test "Subnet" "Public Subnet" "FAIL" "Not found"
}

if ($priv_subnet) {
    Show-Test "PASS" "Private Subnet: $priv_subnet"
    Add-Test "Subnet" "Private Subnet" "PASS" $priv_subnet
} else {
    Show-Test "FAIL" "Private Subnet not found"
    Add-Test "Subnet" "Private Subnet" "FAIL" "Not found"
}

# TEST 3: IGW
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 3: INTERNET GATEWAY SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$igw = terraform output -raw internet_gateway_id 2>$null
if ($igw) {
    Show-Test "PASS" "Internet Gateway: $igw"
    Add-Test "IGW" "IGW Creation" "PASS" $igw
} else {
    Show-Test "FAIL" "IGW not found"
    Add-Test "IGW" "IGW Creation" "FAIL" "Not found"
}

# TEST 4: NAT
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 4: NAT GATEWAY SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$nat = terraform output -raw nat_gateway_id 2>$null
$nat_ip = terraform output -raw nat_gateway_public_ip 2>$null

if ($nat) {
    Show-Test "PASS" "NAT Gateway: $nat"
    Add-Test "NAT" "NAT Creation" "PASS" $nat
    
    if ($nat_ip) {
        Show-Test "PASS" "NAT EIP: $nat_ip"
        Add-Test "NAT" "NAT EIP" "PASS" $nat_ip
    }
} else {
    Show-Test "FAIL" "NAT not found"
    Add-Test "NAT" "NAT Creation" "FAIL" "Not found"
}

# TEST 5: ROUTE TABLES
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 5: ROUTE TABLE SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$pub_rt = terraform output -raw public_route_table_id 2>$null
$priv_rt = terraform output -raw private_route_table_id 2>$null

if ($pub_rt) {
    Show-Test "PASS" "Public Route Table: $pub_rt"
    Add-Test "Route Table" "Public RT" "PASS" $pub_rt
} else {
    Show-Test "FAIL" "Public RT not found"
    Add-Test "Route Table" "Public RT" "FAIL" "Not found"
}

if ($priv_rt) {
    Show-Test "PASS" "Private Route Table: $priv_rt"
    Add-Test "Route Table" "Private RT" "PASS" $priv_rt
} else {
    Show-Test "FAIL" "Private RT not found"
    Add-Test "Route Table" "Private RT" "FAIL" "Not found"
}

# TEST 6: SECURITY GROUPS
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 6: SECURITY GROUP SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$pub_sg = terraform output -raw public_security_group_id 2>$null
$priv_sg = terraform output -raw private_security_group_id 2>$null

if ($pub_sg) {
    Show-Test "PASS" "Public Security Group: $pub_sg"
    Add-Test "Security Group" "Public SG" "PASS" $pub_sg
    
    $sg = aws ec2 describe-security-groups --group-ids $pub_sg --region $region --output json 2>$null | ConvertFrom-Json
    $ssh_rule = $sg.SecurityGroups[0].IpPermissions | Where-Object { $_.FromPort -eq 22 }
    if ($ssh_rule) {
        $ip = $ssh_rule.IpRanges[0].CidrIp
        Show-Test "PASS" "SSH Rule: $ip"
        Add-Test "Security Group" "SSH Rule" "PASS" $ip
    }
} else {
    Show-Test "FAIL" "Public SG not found"
    Add-Test "Security Group" "Public SG" "FAIL" "Not found"
}

if ($priv_sg) {
    Show-Test "PASS" "Private Security Group: $priv_sg"
    Add-Test "Security Group" "Private SG" "PASS" $priv_sg
} else {
    Show-Test "FAIL" "Private SG not found"
    Add-Test "Security Group" "Private SG" "FAIL" "Not found"
}

# TEST 7: EC2 INSTANCES
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 7: EC2 SERVICE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$pub_ec2 = terraform output -raw public_ec2_id 2>$null
$pub_ip = terraform output -raw public_ec2_public_ip 2>$null
$priv_ec2 = terraform output -raw private_ec2_id 2>$null
$priv_ip = terraform output -raw private_ec2_private_ip 2>$null

if ($pub_ec2) {
    Show-Test "PASS" "Public EC2: $pub_ec2"
    Add-Test "EC2" "Public EC2" "PASS" $pub_ec2
    
    if ($pub_ip) {
        Show-Test "PASS" "Public IP: $pub_ip"
        Add-Test "EC2" "Public IP" "PASS" $pub_ip
    }
    
    $ec2 = aws ec2 describe-instances --instance-ids $pub_ec2 --region $region --output json 2>$null | ConvertFrom-Json
    $state = $ec2.Reservations[0].Instances[0].State.Name
    if ($state -eq "running") {
        Show-Test "PASS" "Public EC2 State: running"
        Add-Test "EC2" "Public State" "PASS" "running"
    }
} else {
    Show-Test "FAIL" "Public EC2 not found"
    Add-Test "EC2" "Public EC2" "FAIL" "Not found"
}

if ($priv_ec2) {
    Show-Test "PASS" "Private EC2: $priv_ec2"
    Add-Test "EC2" "Private EC2" "PASS" $priv_ec2
    
    if ($priv_ip) {
        Show-Test "PASS" "Private IP: $priv_ip"
        Add-Test "EC2" "Private IP" "PASS" $priv_ip
    }
    
    $ec2 = aws ec2 describe-instances --instance-ids $priv_ec2 --region $region --output json 2>$null | ConvertFrom-Json
    $state = $ec2.Reservations[0].Instances[0].State.Name
    if ($state -eq "running") {
        Show-Test "PASS" "Private EC2 State: running"
        Add-Test "EC2" "Private State" "PASS" "running"
    }
    
    $public_ip_check = $ec2.Reservations[0].Instances[0].PublicIpAddress
    if (-not $public_ip_check) {
        Show-Test "PASS" "Private EC2 has NO public IP (secure)"
        Add-TestTest "EC2" "No Public IP" "PASS" "Secure"
    }
} else {
    Show-Test "FAIL" "Private EC2 not found"
    Add-Test "EC2" "Private EC2" "FAIL" "Not found"
}

# TEST 8: CONNECTIVITY
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " TEST 8: CONNECTIVITY" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

if (Test-Path "working-key.pem") {
    $ssh = ssh -i working-key.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$pub_ip "echo OK" 2>$null
    if ($ssh -eq "OK") {
        Show-Test "PASS" "SSH to Public EC2 successful"
        Add-Test "Connectivity" "SSH" "PASS" "Connected"
    } else {
        Show-Test "FAIL" "Cannot SSH to Public EC2"
        Add-Test "Connectivity" "SSH" "FAIL" "Failed"
    }
} else {
    Show-Test "SKIP" "No key file - skip connectivity test"
    Add-Test "Connectivity" "SSH" "SKIP" "No key"
}

# SUMMARY
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$pass = ($tests | Where-Object { $_.Status -eq "PASS" }).Count
$fail = ($tests | Where-Object { $_.Status -eq "FAIL" }).Count
$skip = ($tests | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host ""
Write-Host "  PASSED:  $pass" -ForegroundColor Green
Write-Host "  FAILED:  $fail" -ForegroundColor Red
Write-Host "  SKIPPED: $skip" -ForegroundColor Yellow
Write-Host "  TOTAL:   $($tests.Count)"
Write-Host ""

$cats = $tests | Group-Object -Property Cat
Write-Host "Results by Service:" -ForegroundColor Cyan
foreach ($c in $cats) {
    $cp = ($c.Group | Where-Object { $_.Status -eq "PASS" }).Count
    Write-Host "  - $($c.Name): $cp/$($c.Group.Count) passed"
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "SUCCESS: All services working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Infrastructure:" -ForegroundColor Cyan
    Write-Host "  VPC:         $vpc_id"
    Write-Host "  Public EC2:  $pub_ip"
    Write-Host "  Private EC2: $priv_ip"
    Write-Host "  NAT Gateway: $nat_ip"
} else {
    Write-Host "WARNING: $fail service(s) failed!" -ForegroundColor Red
}
Write-Host ""
