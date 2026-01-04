# ============================================================================
# NT548 LAB01 - Network Module Deployment Script
# ============================================================================
# Description: Deploy Network infrastructure (Subnets, IGW, NAT, Routes)
# Dependencies: VPC module must be deployed first
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-network",
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "nt548-lab01",
    [string]$Environment = "dev",
    [string]$PublicSubnetCIDR = "10.0.1.0/24",
    [string]$PrivateSubnetCIDR = "10.0.2.0/24",
    [string]$AvailabilityZone = "ap-southeast-1a"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB01 - Network Module Deployment" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check VPC stack dependency
Write-Host "[1/5] Checking VPC module dependency..." -ForegroundColor Yellow
$vpcStack = aws cloudformation describe-stacks --stack-name "nt548-lab01-vpc" --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] VPC module not found!" -ForegroundColor Red
    Write-Host "  [!] Please deploy VPC module first: .\standalone-modules\vpc\deploy-vpc.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] VPC module found" -ForegroundColor Green

# Check if stack exists
Write-Host ""
Write-Host "[2/5] Checking existing stack..." -ForegroundColor Yellow
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
Write-Host "[3/5] Validating template..." -ForegroundColor Yellow
$templatePath = Join-Path $ScriptDir "network.yaml"
aws cloudformation validate-template --template-body file://$templatePath --region $Region | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Template validation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Template is valid" -ForegroundColor Green

# Deploy stack
Write-Host ""
Write-Host "[4/5] Deploying Network stack..." -ForegroundColor Yellow
Write-Host "  This will create: Subnets, Internet Gateway, NAT Gateway, Route Tables" -ForegroundColor Gray
Write-Host "  Note: NAT Gateway creation takes ~3-5 minutes" -ForegroundColor Gray
Write-Host ""

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $StackName `
    --region $Region `
    --parameter-overrides `
        ProjectName=$ProjectName `
        Environment=$Environment `
        PublicSubnetCIDR=$PublicSubnetCIDR `
        PrivateSubnetCIDR=$PrivateSubnetCIDR `
        AvailabilityZone=$AvailabilityZone `
    --tags `
        Project=$ProjectName `
        Environment=$Environment `
        Module=Network `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Network deployment failed!" -ForegroundColor Red
    exit 1
}

# Get outputs
Write-Host ""
Write-Host "[5/5] Retrieving stack outputs..." -ForegroundColor Yellow
$outputs = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output json | ConvertFrom-Json

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Network Module Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Outputs:" -ForegroundColor Cyan
foreach ($output in $outputs) {
    Write-Host "  $($output.OutputKey): " -NoNewline -ForegroundColor Yellow
    Write-Host "$($output.OutputValue)" -ForegroundColor White
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy Security module: .\standalone-modules\security\deploy-security.ps1" -ForegroundColor Gray
Write-Host "  2. Deploy EC2 module: .\standalone-modules\ec2\deploy-ec2.ps1" -ForegroundColor Gray
Write-Host ""
