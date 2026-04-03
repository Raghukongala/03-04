pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        CLUSTER_NAME = "devops-ecs-cluster"
        SERVICE_NAME = "devops-service"
        ECR_REPO = "ecs-devops-repo"
        TG_NAME = "ecs-devops-tg"
        IAM_ROLE = "ecsTaskExecutionRole"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Raghukongala/03-04.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Force Cleanup (AWS)') {
            steps {
                sh '''
                echo "=== FORCE CLEANUP START ==="

                # Scale down ECS Service
                aws ecs update-service \
                  --cluster $CLUSTER_NAME \
                  --service $SERVICE_NAME \
                  --desired-count 0 || true

                sleep 60

                # Delete ECS Service
                aws ecs delete-service \
                  --cluster $CLUSTER_NAME \
                  --service $SERVICE_NAME \
                  --force || true

                sleep 30

                # Delete Target Group
                TG_ARN=$(aws elbv2 describe-target-groups \
                  --names $TG_NAME \
                  --query "TargetGroups[0].TargetGroupArn" \
                  --output text 2>/dev/null)

                if [ "$TG_ARN" != "None" ]; then
                  aws elbv2 delete-target-group --target-group-arn $TG_ARN || true
                fi

                # Delete ECR Repo
                aws ecr delete-repository \
                  --repository-name $ECR_REPO \
                  --force || true

                # Delete IAM Role
                aws iam detach-role-policy \
                  --role-name $IAM_ROLE \
                  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

                aws iam delete-role \
                  --role-name $IAM_ROLE || true

                echo "=== FORCE CLEANUP DONE ==="
                '''
            }
        }

        stage('Terraform Destroy (Safe)') {
            steps {
                sh 'terraform destroy -auto-approve || true'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        success {
            echo "🔥 Infra Rebuilt Successfully"
        }
        failure {
            echo "❌ Pipeline Failed"
        }
    }
}
