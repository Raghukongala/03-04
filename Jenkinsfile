pipeline {
agent any

```
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

    stage('Destroy Old Resources') {
        steps {
            sh '''
            echo "Destroying old resources (if any)..."
            terraform destroy -auto-approve || true
            '''
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
        echo "Infrastructure Provisioned Successfully 🚀"
    }
    failure {
        echo "Pipeline Failed ❌ Check logs"
    }
}
```

}
