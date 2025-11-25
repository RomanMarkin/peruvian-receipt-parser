# Infrastructure Provision in AWS

### Use global Terraform cache on your local machine (Optional)
To prevent Terraform cache duplication in each module directory, you can optionally do:

    mkdir -p $HOME/.terraform.d/plugin-cache
    echo "plugin_cache_dir = \"$HOME/.terraform.d/plugin-cache\"" > ~/.terraformrc

### Create AWS Profile
Create an AWS profile for the user running the Terraform deployment. Name the profile `donat-deploy` (as referenced in `common.tfvars`).

    aws configure --profile donat-deploy

### Add permissions to the AWS deployment user
IAM → Users → (select user) → Permissions tab → Add inline policy → JSON

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "S3FullAccess",
                "Effect": "Allow",
                "Action": [
                    "s3:*"
                ],
                "Resource": "*"
            },
            {
                "Sid": "IAMManagement",
                "Effect": "Allow",
                "Action": [
                    "iam:CreateRole",
                    "iam:GetRole",
                    "iam:DeleteRole",
                    "iam:PassRole",
                    "iam:TagRole",
                    "iam:ListRoleTags",
                    "iam:UpdateAssumeRolePolicy",
                    "iam:AttachRolePolicy",
                    "iam:DetachRolePolicy",
                    "iam:ListAttachedRolePolicies",
                    "iam:PutRolePolicy",
                    "iam:GetRolePolicy",
                    "iam:ListRolePolicies",
                    "iam:DeleteRolePolicy",
                    "iam:ListInstanceProfilesForRole",
                    "iam:RemoveRoleFromInstanceProfile",
                    "iam:DeleteInstanceProfile",
                    "iam:CreateServiceLinkedRole"
                ],
                "Resource": "*"
            },
            {
                "Sid": "ECSManagement",
                "Effect": "Allow",
                "Action": [
                    "ecs:CreateCluster",
                    "ecs:DescribeClusters",
                    "ecs:DeleteCluster",
                    "ecs:RegisterTaskDefinition",
                    "ecs:DeregisterTaskDefinition",
                    "ecs:DescribeTaskDefinition",
                    "ecs:CreateService",
                    "ecs:UpdateService",
                    "ecs:DeleteService",
                    "ecs:DescribeServices",
                    "ecs:TagResource"
                ],
                "Resource": "*"
            },
            {
                "Sid": "ECRManagement",
                "Effect": "Allow",
                "Action": [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "ecr:CompleteLayerUpload",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CreateRepository",
                    "ecr:DescribeRepositories",
                    "ecr:DescribeImages",
                    "ecr:ListTagsForResource",
                    "ecr:DeleteRepository",
                    "ecr:PutImage",
                    "ecr:SetRepositoryPolicy",
                    "ecr:DeleteRepositoryPolicy",
                    "ecr:TagResource"
                ],
                "Resource": "*"
            },
            {
                "Sid": "LogsManagement",
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:PutRetentionPolicy",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams",
                    "logs:ListTagsForResource",
                    "logs:TagResource",
                    "logs:DeleteLogGroup"
                ],
                "Resource": "*"
            },
            {
                "Sid": "LoadBalancerManagement",
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:CreateLoadBalancer",
                    "elasticloadbalancing:DeleteLoadBalancer",
                    "elasticloadbalancing:CreateTargetGroup",
                    "elasticloadbalancing:DeleteTargetGroup",
                    "elasticloadbalancing:CreateListener",
                    "elasticloadbalancing:DeleteListener",
                    "elasticloadbalancing:AddTags",
                    "elasticloadbalancing:RemoveTags",
                    "elasticloadbalancing:ModifyTargetGroupAttributes",
                    "elasticloadbalancing:ModifyLoadBalancerAttributes",
                    "elasticloadbalancing:SetSecurityGroups",
                    "elasticloadbalancing:SetSubnets",
                    "elasticloadbalancing:Describe*"
                ],
                "Resource": "*"
            },
            {
                "Sid": "EC2andNetworking",
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateVpc",
                    "ec2:CreateSubnet",
                    "ec2:CreateInternetGateway",
                    "ec2:CreateRouteTable",
                    "ec2:CreateSecurityGroup",
                    "ec2:CreateNatGateway",
                    "ec2:AllocateAddress",
                    "ec2:Describe*",
                    "ec2:Get*",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:AttachInternetGateway",
                    "ec2:DetachInternetGateway",
                    "ec2:DeleteVpc",
                    "ec2:DeleteSubnet",
                    "ec2:DeleteInternetGateway",
                    "ec2:DeleteRouteTable",
                    "ec2:DeleteSecurityGroup",
                    "ec2:DeleteNatGateway",
                    "ec2:ReleaseAddress",
                    "ec2:DisassociateAddress",
                    "ec2:AssociateAddress",
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:AssociateRouteTable",
                    "ec2:DisassociateRouteTable",
                    "ec2:ModifyVpcAttribute",
                    "ec2:CreateTags",
                    "ec2:CreateRoute",
                    "ec2:DeleteRoute",
                    "ec2:ReplaceRoute",
                    "ec2:ReplaceNetworkAclEntry",
                    "ec2:CreateNetworkAclEntry",
                    "ec2:DeleteNetworkAclEntry"
                ],
                "Resource": "*"
            }
        ]
    }

## Create global project infrastructure (for both production and staging environments) 
    
    cd ./peruvian-receipt-parser/terraform/global  
    terraform init       
    terraform apply \
      -var-file="../common.tfvars"

## Create staging infrastructure 
    
    cd ./peruvian-receipt-parser/terraform/environments/staging
    terraform init
    terraform apply \
      -var-file="../../common.tfvars" \
      -var-file="staging.tfvars"

In case you need to destroy infrastructure:

    terraform destroy \
      -var-file="../../common.tfvars" \
      -var-file="staging.tfvars"

## Create production infrastructure 
    
    cd ./peruvian-receipt-parser/terraform/environments/production
    terraform init
    terraform apply \
      -var-file="../../common.tfvars" \
      -var-file="production.tfvars"

In case you need to destroy infrastructure:

    terraform destroy \
      -var-file="../../common.tfvars" \
      -var-file="production.tfvars"