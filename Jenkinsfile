pipeline {
    agent any

    environment {
        AWS_REGION   = "ap-south-1"
        CLUSTER_NAME = "devops-ecs-cluster"
        SERVICE_NAME = "devops-service"
        ECR_REPO     = "ecs-devops-repo"
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

        stage('Destroy Old Infrastructure') {
            steps {
                withCredentials([
                    string(credentialsId: 'Accesskey', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'Secret access key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    export AWS_REGION=$AWS_REGION

                    echo "Destroying old infrastructure..."

                    aws ecs update-service \
                      --cluster $CLUSTER_NAME \
                      --service $SERVICE_NAME \
                      --desired-count 0 || true

                    sleep 30

                    aws ecs delete-service \
                      --cluster $CLUSTER_NAME \
                      --service $SERVICE_NAME \
                      --force || true

                    aws ecr delete-repository \
                      --repository-name $ECR_REPO \
                      --force || true

                    terraform destroy -auto-approve || true
                    '''
                }
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
            echo "🚀 Terraform Apply Successful"
        }
        failure {
            echo "❌ Terraform Apply Failed"
        }
    }
}
