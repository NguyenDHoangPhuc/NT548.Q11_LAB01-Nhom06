# NT548 LAB 01 - CloudFormation Deployment Script

param(
    [string]$StackName = "nt548-lab01-stack",
    [string]$Region = "ap-southeast-1"
)

Write-Host "Deploying CloudFormation stack..." -ForegroundColor Cyan

# Validate template
aws cloudformation validate-template --template-body file://main.yaml --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Template validation failed!" -ForegroundColor Red
    exit 1
}

# Create stack
aws cloudformation create-stack --stack-name $StackName --template-body file://main.yaml --parameters file://parameters.json --region $Region --capabilities CAPABILITY_IAM

Write-Host "Stack creation initiated. Waiting..." -ForegroundColor Yellow

# Wait for completion
aws cloudformation wait stack-create-complete --stack-name $StackName --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    aws cloudformation describe-stacks --stack-name $StackName --region $Region --query 'Stacks[0].Outputs'
} else {
    Write-Host "DEPLOYMENT FAILED!" -ForegroundColor Red
}
