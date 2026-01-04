# ============================================================================
# NT548 LAB 01 - CloudFormation Cleanup Script
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-stack",
    [string]$Region = "ap-southeast-1"
)

Write-Host ""
Write-Host "========================================================" -ForegroundColor Red
Write-Host "  NT548 LAB 01 - CloudFormation Cleanup" -ForegroundColor Red
Write-Host "========================================================" -ForegroundColor Red
Write-Host ""
Write-Host "[WARNING] This will DELETE all resources!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Stack: $StackName" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Type 'yes' to confirm deletion"
if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "[1/3] Checking stack..." -ForegroundColor Yellow
$stackInfo = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Stack not found" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Stack found" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Deleting stack..." -ForegroundColor Yellow
aws cloudformation delete-stack --stack-name $StackName --region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Failed" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Deletion initiated" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Waiting for completion..." -ForegroundColor Yellow
Write-Host "  This takes 3-5 minutes..." -ForegroundColor Cyan
Write-Host ""

aws cloudformation wait stack-delete-complete --stack-name $StackName --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS - All resources deleted!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  FAILED - Check AWS Console" -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}
