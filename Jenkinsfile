pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose Terraform Action')
    }

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

        stage('Destroy Old Infrastructure (Before Apply)') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
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
                sh 'terraform destroy -auto-approve'
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
