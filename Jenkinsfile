pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose Terraform Action')
    }

    environment {
        AWS_REGION = "ap-south-1"
        CLUSTER_NAME = "devops-ecs-cluster"
        SERVICE_NAME = "devops-service"
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

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                sh '''
                echo "=== STEP 1: Scale down ECS service ==="

                aws ecs update-service \
                  --cluster $CLUSTER_NAME \
                  --service $SERVICE_NAME \
                  --desired-count 0 || true

                echo "Waiting for tasks to stop..."
                sleep 60

                echo "=== STEP 2: Delete ECS service ==="

                aws ecs delete-service \
                  --cluster $CLUSTER_NAME \
                  --service $SERVICE_NAME \
                  --force || true

                echo "Waiting for service to become inactive..."

                aws ecs wait services-inactive \
                  --cluster $CLUSTER_NAME \
                  --services $SERVICE_NAME || true

                echo "=== STEP 3: Terraform destroy ==="

                terraform destroy -auto-approve
                '''
            }
        }
    }

    post {
        success {
            echo "🚀 Terraform ${params.ACTION} Successful"
        }
        failure {
            echo "❌ Terraform ${params.ACTION} Failed"
        }
    }
}
