# ============================================================================
# NT548 LAB01 - Deploy All Modules (Master Script)
# ============================================================================
# Description: Deploy all CloudFormation modules in correct order
# Architecture: Standalone Modules (No S3 Required)
# ============================================================================

param(
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "nt548-lab01",
    [string]$Environment = "dev",
    [string]$KeyName = "working-key"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB01 - CloudFormation Standalone Modules" -ForegroundColor Cyan
Write-Host "  Deploy All Modules in Sequence" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will deploy 4 modules in order:" -ForegroundColor Yellow
Write-Host "  1. VPC Module" -ForegroundColor White
Write-Host "  2. Network Module (Subnets, IGW, NAT, Routes)" -ForegroundColor White
Write-Host "  3. Security Module (Security Groups)" -ForegroundColor White
Write-Host "  4. EC2 Module (Public + Private Instances)" -ForegroundColor White
Write-Host ""
Write-Host "Architecture: Standalone CloudFormation Stacks" -ForegroundColor Cyan
Write-Host "  ✅ Each module = 1 YAML + 1 Script" -ForegroundColor Green
Write-Host "  ✅ NO S3 required" -ForegroundColor Green
Write-Host "  ✅ 100% Module Architecture" -ForegroundColor Green
Write-Host ""
Write-Host "Estimated time: 8-10 minutes" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "Continue with deployment? (y/n)"
if ($response -ne 'y') {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MODULE 1/4: VPC" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

& "$ScriptDir\standalone-modules\vpc\deploy-vpc.ps1" `
    -Region $Region `
    -ProjectName $ProjectName `
    -Environment $Environment

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] VPC module deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MODULE 2/4: NETWORK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

& "$ScriptDir\standalone-modules\network\deploy-network.ps1" `
    -Region $Region `
    -ProjectName $ProjectName `
    -Environment $Environment

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Network module deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MODULE 3/4: SECURITY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

& "$ScriptDir\standalone-modules\security\deploy-security.ps1" `
    -Region $Region `
    -ProjectName $ProjectName `
    -Environment $Environment

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Security module deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MODULE 4/4: EC2" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

& "$ScriptDir\standalone-modules\ec2\deploy-ec2.ps1" `
    -Region $Region `
    -ProjectName $ProjectName `
    -Environment $Environment `
    -KeyName $KeyName

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] EC2 module deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  🎉 ALL MODULES DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ✅ 4 CloudFormation Stacks Created" -ForegroundColor Green
Write-Host "  ✅ Module Architecture Implemented" -ForegroundColor Green
Write-Host "  ✅ No S3 Required (Standalone)" -ForegroundColor Green
Write-Host ""
Write-Host "Stack Names:" -ForegroundColor Cyan
Write-Host "  - $ProjectName-vpc" -ForegroundColor White
Write-Host "  - $ProjectName-network" -ForegroundColor White
Write-Host "  - $ProjectName-security" -ForegroundColor White
Write-Host "  - $ProjectName-ec2" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 2-3 minutes for EC2 initialization" -ForegroundColor Gray
Write-Host "  2. Test web access to public instance" -ForegroundColor Gray
Write-Host "  3. SSH to instances and verify connectivity" -ForegroundColor Gray
Write-Host "  4. Take screenshots for report" -ForegroundColor Gray
Write-Host ""
Write-Host "Cleanup:" -ForegroundColor Cyan
Write-Host "  Run: .\delete-all-modules.ps1" -ForegroundColor Gray
Write-Host ""
