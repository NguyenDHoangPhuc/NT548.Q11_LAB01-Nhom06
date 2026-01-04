# ============================================================================
# NT548 LAB01 - EC2 Module Deployment Script
# ============================================================================
# Description: Deploy EC2 instances (Public Bastion + Private Instance)
# Dependencies: VPC, Network, Security modules must be deployed first
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-ec2",
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "nt548-lab01",
    [string]$Environment = "dev",
    [string]$KeyName = "working-key",
    [string]$InstanceType = "t3.micro"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB01 - EC2 Module Deployment" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check dependencies
Write-Host "[1/6] Checking module dependencies..." -ForegroundColor Yellow

$requiredStacks = @("nt548-lab01-vpc", "nt548-lab01-network", "nt548-lab01-security")
foreach ($stack in $requiredStacks) {
    $exists = aws cloudformation describe-stacks --stack-name $stack --region $Region 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] Required module not found: $stack" -ForegroundColor Red
        Write-Host "  [!] Please deploy all prerequisite modules first" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  [OK] Found: $stack" -ForegroundColor Green
}

# Check if stack exists
Write-Host ""
Write-Host "[2/6] Checking existing stack..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$stackExists = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [!] Stack '$StackName' already exists!" -ForegroundColor Yellow
    $response = Read-Host "  Do you want to update it? (y/n)"
    if ($response -ne 'y') {
        Write-Host "  [X] Deployment cancelled" -ForegroundColor Red
        exit 0
    }
} else {
    Write-Host "  [OK] Stack not found, will create new stack" -ForegroundColor Green
}

# Validate template
Write-Host ""
Write-Host "[3/6] Validating template..." -ForegroundColor Yellow
$templatePath = Join-Path $ScriptDir "ec2.yaml"

# Skip validation due to path encoding issues with Vietnamese characters
# Template will be validated during deployment
Write-Host "  [OK] Template validation skipped (will validate during deploy)" -ForegroundColor Green

# Check Key Pair
Write-Host ""
Write-Host "[4/6] Checking EC2 Key Pair..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$keyPair = aws ec2 describe-key-pairs --key-names $KeyName --region $Region 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Key pair '$KeyName' not found!" -ForegroundColor Red
    Write-Host "  [!] Please create the key pair first or specify different key name" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Key pair found: $KeyName" -ForegroundColor Green

# Deploy stack
Write-Host ""
Write-Host "[5/6] Deploying EC2 stack..." -ForegroundColor Yellow
Write-Host "  Creating 2 EC2 instances (Public + Private)..." -ForegroundColor Gray
Write-Host "  This may take 3-5 minutes..." -ForegroundColor Gray
Write-Host ""

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $StackName `
    --region $Region `
    --parameter-overrides `
        ProjectName=$ProjectName `
        Environment=$Environment `
        KeyName=$KeyName `
        InstanceType=$InstanceType `
    --tags `
        Project=$ProjectName `
        Environment=$Environment `
        Module=EC2 `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] EC2 deployment failed!" -ForegroundColor Red
    exit 1
}

# Get outputs
Write-Host ""
Write-Host "[6/6] Retrieving stack outputs..." -ForegroundColor Yellow
$outputs = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output json | ConvertFrom-Json

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  EC2 Module Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Instance Details:" -ForegroundColor Cyan
foreach ($output in $outputs) {
    Write-Host "  $($output.OutputKey): " -NoNewline -ForegroundColor Yellow
    Write-Host "$($output.OutputValue)" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  ALL MODULES DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
