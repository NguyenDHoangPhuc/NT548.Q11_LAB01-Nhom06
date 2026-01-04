# ============================================================================
# NT548 LAB 01 - Copy Key and Connect to Private EC2
# ============================================================================
# Description: Helper script to copy SSH key to Public EC2 and connect to Private EC2
# Usage: .\copy-key-and-connect.ps1
# ============================================================================

param(
    [string]$StackName = "nt548-lab01-stack",
    [string]$Region = "ap-southeast-1",
    [string]$KeyFile = "working-key.pem"
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  NT548 LAB 01 - Private EC2 Connection Helper" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "✗ Key file not found: $KeyFile" -ForegroundColor Red
    exit 1
}

# Get IPs from stack
Write-Host "Getting EC2 IP addresses..." -ForegroundColor Yellow
try {
    $outputs = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs' | ConvertFrom-Json
    
    $outputHash = @{}
    foreach ($output in $outputs) {
        $outputHash[$output.OutputKey] = $output.OutputValue
    }
    
    $publicIP = $outputHash['PublicEC2PublicIP']
    $privateIP = $outputHash['PrivateEC2PrivateIP']
    
    Write-Host "  ✓ Public EC2 IP: $publicIP" -ForegroundColor Green
    Write-Host "  ✓ Private EC2 IP: $privateIP" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to get EC2 IPs" -ForegroundColor Red
    exit 1
}

# Step 1: Copy key to Public EC2
Write-Host ""
Write-Host "[Step 1/2] Copying SSH key to Public EC2..." -ForegroundColor Yellow
Write-Host "  Command: scp -i $KeyFile $KeyFile ubuntu@${publicIP}:/home/ubuntu/key.pem" -ForegroundColor Cyan

try {
    scp -i $KeyFile $KeyFile ubuntu@${publicIP}:/home/ubuntu/key.pem
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Key copied successfully" -ForegroundColor Green
    } else {
        throw "SCP failed"
    }
} catch {
    Write-Host "  ✗ Failed to copy key" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually copy the key:" -ForegroundColor Yellow
    Write-Host "  scp -i $KeyFile $KeyFile ubuntu@${publicIP}:/home/ubuntu/key.pem" -ForegroundColor Cyan
    exit 1
}

# Step 2: SSH to Public EC2 with instructions
Write-Host ""
Write-Host "[Step 2/2] Connecting to Public EC2..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  You are now connected to Public EC2" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To connect to Private EC2, run these commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  chmod 400 key.pem" -ForegroundColor Yellow
Write-Host "  ssh -i key.pem ubuntu@$privateIP" -ForegroundColor Yellow
Write-Host ""
Write-Host "To test Private EC2 internet connectivity (via NAT):" -ForegroundColor Cyan
Write-Host "  curl http://checkip.amazonaws.com" -ForegroundColor Yellow
Write-Host "  (Should show NAT Gateway IP: $($outputHash['NATGatewayEIP']))" -ForegroundColor White
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# SSH to Public EC2
ssh -i $KeyFile ubuntu@$publicIP
