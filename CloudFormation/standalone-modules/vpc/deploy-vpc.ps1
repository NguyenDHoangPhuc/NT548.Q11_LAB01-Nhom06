# ============================================================================
# NT548 LAB01 - VPC Module Deployment Script
# ============================================================================
# Description: Deploy VPC infrastructure as standalone CloudFormation stack
# Dependencies: None (first module to deploy)
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-vpc",
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "nt548-lab01",
    [string]$Environment = "dev",
    [string]$VpcCIDR = "10.0.0.0/16"
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB01 - VPC Module Deployment" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if stack exists
Write-Host "[1/4] Checking existing stack..." -ForegroundColor Yellow
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
    $action = "update"
} else {
    Write-Host "  [OK] Stack not found, will create new stack" -ForegroundColor Green
    $action = "create"
}

# Validate template
Write-Host ""
Write-Host "[2/4] Validating CloudFormation template..." -ForegroundColor Yellow
$templatePath = Join-Path $ScriptDir "vpc.yaml"
aws cloudformation validate-template --template-body file://$templatePath --region $Region | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Template validation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Template is valid" -ForegroundColor Green

# Deploy stack
Write-Host ""
Write-Host "[3/4] Deploying VPC stack..." -ForegroundColor Yellow
Write-Host "  Stack Name: $StackName" -ForegroundColor Gray
Write-Host "  Region: $Region" -ForegroundColor Gray
Write-Host "  VPC CIDR: $VpcCIDR" -ForegroundColor Gray
Write-Host ""

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $StackName `
    --region $Region `
    --parameter-overrides `
        ProjectName=$ProjectName `
        Environment=$Environment `
        VpcCIDR=$VpcCIDR `
    --tags `
        Project=$ProjectName `
        Environment=$Environment `
        Module=VPC `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] VPC deployment failed!" -ForegroundColor Red
    exit 1
}

# Get outputs
Write-Host ""
Write-Host "[4/4] Retrieving stack outputs..." -ForegroundColor Yellow
$outputs = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output json | ConvertFrom-Json

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  VPC Module Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Outputs:" -ForegroundColor Cyan
foreach ($output in $outputs) {
    Write-Host "  $($output.OutputKey): " -NoNewline -ForegroundColor Yellow
    Write-Host "$($output.OutputValue)" -ForegroundColor White
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy Network module: .\standalone-modules\network\deploy-network.ps1" -ForegroundColor Gray
Write-Host "  2. Deploy Security module: .\standalone-modules\security\deploy-security.ps1" -ForegroundColor Gray
Write-Host "  3. Deploy EC2 module: .\standalone-modules\ec2\deploy-ec2.ps1" -ForegroundColor Gray
Write-Host ""
