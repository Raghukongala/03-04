resource "aws_ecr_repository" "repo" {
  name = "ecs-devops-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecs-devops-repo"
  }
}
