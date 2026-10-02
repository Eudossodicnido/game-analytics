#ECR repository
import {
  to = aws_ecr_repository.pipeline
  identity = {
    name = "game-analytics"
  }
}

resource "aws_ecr_repository" "pipeline" {
  name                 = "game-analytics"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = "game-analytics"
  }

}

#Lifecycle policy
import {
  to = aws_ecr_lifecycle_policy.pipeline
  identity = {
    repository = "game-analytics"
  }
}

resource "aws_ecr_lifecycle_policy" "pipeline" {
  repository = aws_ecr_repository.pipeline.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "keep last 3 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
