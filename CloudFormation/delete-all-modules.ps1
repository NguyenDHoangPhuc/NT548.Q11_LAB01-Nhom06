# ============================================================================
# NT548 LAB01 - Delete All Modules (Cleanup Script)
# ============================================================================
# Description: Delete all CloudFormation module stacks
# Order: Reverse order of deployment (EC2 -> Security -> Network -> VPC)
# ============================================================================

param(
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "nt548-lab01"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "  NT548 LAB01 - Delete All Modules" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "This will delete 4 CloudFormation stacks:" -ForegroundColor Yellow
Write-Host "  - $ProjectName-ec2" -ForegroundColor White
Write-Host "  - $ProjectName-security" -ForegroundColor White
Write-Host "  - $ProjectName-network" -ForegroundColor White
Write-Host "  - $ProjectName-vpc" -ForegroundColor White
Write-Host ""
Write-Host "WARNING: This action cannot be undone!" -ForegroundColor Red
Write-Host ""

$response = Read-Host "Are you sure you want to delete all stacks? (yes/no)"
if ($response -ne 'yes') {
    Write-Host "Deletion cancelled" -ForegroundColor Yellow
    exit 0
}

# Delete in reverse order (dependencies)
$stacks = @(
    "$ProjectName-ec2",
    "$ProjectName-security",
    "$ProjectName-network",
    "$ProjectName-vpc"
)

Write-Host ""
Write-Host "Starting deletion process..." -ForegroundColor Yellow
Write-Host ""

foreach ($stack in $stacks) {
    Write-Host "Deleting stack: $stack" -ForegroundColor Cyan
    
    $exists = aws cloudformation describe-stacks --stack-name $stack --region $Region 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        aws cloudformation delete-stack --stack-name $stack --region $Region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Deletion initiated for $stack" -ForegroundColor Green
            Write-Host "  [!] Waiting for deletion to complete..." -ForegroundColor Yellow
            
            aws cloudformation wait stack-delete-complete --stack-name $stack --region $Region 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Stack deleted successfully: $stack" -ForegroundColor Green
            } else {
                Write-Host "  [!] Stack deletion may still be in progress: $stack" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [X] Failed to initiate deletion for $stack" -ForegroundColor Red
        }
    } else {
        Write-Host "  [!] Stack not found: $stack (already deleted or never created)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Cleanup Process Completed" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Verify deletion:" -ForegroundColor Cyan
Write-Host "  aws cloudformation list-stacks --region $Region | Select-String '$ProjectName'" -ForegroundColor Gray
Write-Host ""
