# ============================================================================
# NT548 LAB 01 - SSH Connection Helper Script
# ============================================================================
# Description: Quick SSH connection to Public EC2
# Usage: .\ssh-connect.ps1
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-stack",
    [string]$Region = "ap-southeast-1",
    [string]$KeyFile = "working-key.pem"
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB 01 - SSH Connection Helper" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "✗ Key file not found: $KeyFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure the key file exists in the current directory." -ForegroundColor Yellow
    Write-Host "You can create it with:" -ForegroundColor Yellow
    Write-Host "  aws ec2 create-key-pair --key-name nt548-lab01-key --region $Region --query 'KeyMaterial' --output text | Out-File -FilePath $KeyFile -Encoding ASCII" -ForegroundColor Cyan
    exit 1
}

# Get Public EC2 IP from stack
Write-Host "Getting Public EC2 IP address..." -ForegroundColor Yellow
try {
    $publicIP = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs[?OutputKey==`PublicEC2PublicIP`].OutputValue' `
        --output text
    
    if (-not $publicIP -or $publicIP -eq "") {
        throw "Public IP not found"
    }
    
    Write-Host "  ✓ Public IP: $publicIP" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to get Public EC2 IP" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure the stack is deployed:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1" -ForegroundColor Cyan
    exit 1
}

# Connect via SSH
Write-Host ""
Write-Host "Connecting to Public EC2..." -ForegroundColor Yellow
Write-Host "  Command: ssh -i $KeyFile ubuntu@$publicIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  If connection fails, check:" -ForegroundColor Yellow
Write-Host "  1. Your IP is whitelisted in Security Group" -ForegroundColor White
Write-Host "  2. EC2 instance is running" -ForegroundColor White
Write-Host "  3. Key file permissions are correct" -ForegroundColor White
Write-Host ""
Write-Host "Connecting..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# SSH command
ssh -i $KeyFile ubuntu@$publicIP
