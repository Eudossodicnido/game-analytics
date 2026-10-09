#Cluster
import {
  to = aws_ecs_cluster.pipeline
  identity = {
    name = "game-analytics-cluster"
  }
}

resource "aws_ecs_cluster" "pipeline" {
  name = "game-analytics-cluster"
  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
  tags = {
    Project = "game-analytics"
  }
}


#Capacity Provider
import {
  to = aws_ecs_cluster_capacity_providers.pipeline
  id = "game-analytics-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "pipeline" {
  cluster_name       = aws_ecs_cluster.pipeline.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}


#Task Definition
import {
  to = aws_ecs_task_definition.pipeline
  identity = {
    family   = "game-analytics"
    revision = 5
  }
}

resource "aws_ecs_task_definition" "pipeline" {
  family                   = "game-analytics"
  skip_destroy             = true
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      "name" : "game-analytics",
      "image" : "649473075374.dkr.ecr.eu-central-1.amazonaws.com/game-analytics:df387f9",
      "cpu" : 0,
      "portMappings" : [],
      "essential" : true,
      "environment" : [
        {
          "name" : "ENV",
          "value" : "prod"
        },
        {
          "name" : "S3_BUCKET_NAME",
          "value" : "rawg-pipeline-videogames-649473075374-eu-central-1-an"
        },
        {
          "name" : "AWS_REGION",
          "value" : "eu-central-1"
        }
      ],
      "environmentFiles" : [],
      "mountPoints" : [],
      "volumesFrom" : [],
      "secrets" : [
        {
          "name" : "RAWG_API_KEY",
          "valueFrom" : "arn:aws:ssm:eu-central-1:649473075374:parameter/game-analytics/rawg-api-key"
        }
      ],
      "ulimits" : [],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/game-analytics",
          "awslogs-create-group" : "true",
          "awslogs-region" : "eu-central-1",
          "awslogs-stream-prefix" : "ecs"
        },
        "secretOptions" : []
      },
      "systemControls" : []

    }
  ])
  task_role_arn      = "arn:aws:iam::649473075374:role/game-analytics-task-role"
  execution_role_arn = "arn:aws:iam::649473075374:role/game-analytics-execution-role"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  tags = {
    Project = "game-analytics"
  }
}

