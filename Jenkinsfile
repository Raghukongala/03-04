pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose Terraform Action')
    }

    environment {
        AWS_REGION = "ap-south-1"
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
                echo "Stopping ECS service before destroy..."

                aws ecs update-service \
                  --cluster devops-ecs-cluster \
                  --service devops-service \
                  --desired-count 0 || true

                sleep 60

                aws ecs delete-service \
                  --cluster devops-ecs-cluster \
                  --service devops-service \
                  --force || true

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
