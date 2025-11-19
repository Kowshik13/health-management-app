<#
Cleanup script for demo infra created by deploy.ps1
Use carefully — this will delete replication config, remove replica bucket (force), terminate EC2 instance, delete keypair (optional) and remove the VPC CloudFormation stack.
#>
param(
    [string]$EnvName = "dev",
    [string]$ReplicaRegion = "us-east-1",
    [string]$StackName = "health-infra-vpc-$EnvName",
    [string]$SourceBucket = "",
    [string]$ReplicaBucket = "",
    [string]$InstanceId = "",
    [switch]$DeleteKeyPair = $false
)

function Get-AccountId {
    (aws sts get-caller-identity --output json | ConvertFrom-Json).Account
}

# derive defaults when possible
$AccountId = Get-AccountId
if (-not $SourceBucket -or $SourceBucket -eq "") { $SourceBucket = "hm-static-site-$EnvName-$AccountId" }
if (-not $ReplicaBucket -or $ReplicaBucket -eq "") { $ReplicaBucket = "hm-static-site-replica-$EnvName-$AccountId-$ReplicaRegion" }

Write-Output "This will attempt to clean up the following resources using the current AWS CLI credentials:"
Write-Output "  Source bucket: $SourceBucket"
Write-Output "  Replica bucket: $ReplicaBucket"
Write-Output "  CloudFormation stack: $StackName"
if ($InstanceId -ne "") { Write-Output "  EC2 instance: $InstanceId" }
if ($DeleteKeyPair) { Write-Output "  Will attempt to delete key-pair associated with health-demo-key-$AccountId-$EnvName" }

$confirm = Read-Host "Type 'YES' to continue"
if ($confirm -ne 'YES') { Write-Output 'Aborting cleanup.'; exit 0 }

# 1) Remove replication configuration from source bucket (if present)
Write-Output "Deleting replication config from source bucket $SourceBucket (if any)"
try {
    aws s3api delete-bucket-replication --bucket $SourceBucket --region $(aws configure get region) 2>$null
    Write-Output "Requested deletion of replication configuration (succeeded or none existed)."
} catch {
    Write-Output "delete-bucket-replication returned an error (continuing): $_"
}

# 2) Delete replica bucket (force) if it exists
Write-Output "Attempting to remove replica bucket $ReplicaBucket"
try {
    $hb = aws s3api head-bucket --bucket $ReplicaBucket 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Replica bucket exists — removing all objects and the bucket (force)"
        aws s3 rb s3://$ReplicaBucket --force --region $ReplicaRegion
        Write-Output "Replica bucket removal requested"
    } else { Write-Output "Replica bucket not found — skipping" }
} catch {
    Write-Output "Error checking/removing replica bucket (continuing): $_"
}

# 3) Terminate EC2 instance if provided
if ($InstanceId -ne "") {
    Write-Output "Terminating EC2 instance $InstanceId"
    try {
        aws ec2 terminate-instances --instance-ids $InstanceId --region $(aws configure get region) | Out-Null
        Write-Output "Requested instance termination. Waiting for termination..."
        aws ec2 wait instance-terminated --instance-ids $InstanceId --region $(aws configure get region)
        Write-Output "Instance terminated"
    } catch {
        Write-Output "Error terminating instance (continuing): $_"
    }
}

# 4) Delete demo keypair from AWS and local file (optional)
$keyName = "health-demo-key-$AccountId-$EnvName"
if ($DeleteKeyPair) {
    Write-Output "Deleting key pair $keyName from AWS and local file if present"
    try { aws ec2 delete-key-pair --key-name $keyName --region $(aws configure get region) 2>$null; Write-Output "Requested AWS key-pair deletion" } catch { Write-Output "AWS delete-key-pair error: $_" }
    $keyFile = Join-Path (Get-Location) "$keyName.pem"
    if (Test-Path $keyFile) { Remove-Item $keyFile -Force; Write-Output "Removed local key file $keyFile" }
}

# 5) Delete CloudFormation stack
Write-Output "Deleting CloudFormation stack $StackName"
try {
    aws cloudformation delete-stack --stack-name $StackName --region $(aws configure get region)
    Write-Output "Delete stack requested. You can monitor deletion in CloudFormation console or with 'aws cloudformation describe-stacks'"
} catch {
    Write-Output "Error deleting stack (continuing): $_"
}

Write-Output "Cleanup script completed (requested operations may be in progress)."
