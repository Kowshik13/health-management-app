Infra folder

This folder contains a small, student-budget-friendly infra deployment:

1) `vpc-stack.yaml` - CloudFormation template that creates a minimal VPC (2 public, 2 private subnets). NAT Gateway is not created to avoid hourly costs. The VPC is provided for future private resources and does not attach to the Lambdas in the app.

2) `deploy.ps1` - PowerShell deployment script which:
   - Deploys the VPC CloudFormation stack into the current AWS CLI region.
   - Creates a replica S3 bucket in the chosen replica region (default `us-east-1`).
   - Enables versioning on the source and replica buckets.
   - Creates an IAM role for S3 replication and configures replication from the source → replica bucket.
   - Applies a lifecycle on the replica bucket that expires objects after 3 days to limit cost for a short demo.

Usage (from repo root):

  cd infra
  .\deploy.ps1

Important notes and cost safety:
- The script expects the static site source bucket to be named `hm-static-site-<env>-<accountId>` by default (env defaults to `dev`). If the script cannot find that bucket it will prompt you to paste the actual source bucket name.
- Cross-region replication will incur S3 PUT and inter-region transfer costs. The script sets a 3-day expiry policy on replicated objects to reduce cost for short demos.
- The VPC does not include a NAT Gateway. If you need outbound access from private subnets, enabling NAT will add cost; change the `EnableNAT` parameter in `deploy.ps1` to true and manually configure NAT after understanding costs.

Rollback / cleanup:
- Delete the replication configuration from the source bucket:
  aws s3api delete-bucket-replication --bucket <source-bucket>
- Delete the replica bucket (and its versions):
  aws s3 rb s3://<replica-bucket> --force
- Delete the CloudFormation stack that created the VPC:
  aws cloudformation delete-stack --stack-name health-infra-vpc-<env>

If you want me to run the deploy now, confirm the replica region (default `us-east-1`) and that I may use the current AWS CLI credentials to deploy. I will not enable NAT unless you explicitly request it.
