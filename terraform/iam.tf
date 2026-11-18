# IAM
# Roles and policies that run the pipeline and send failure alerts.
# The Terraform role is created by hand and stays outside this configuration.


# ECS execution role

import {
  to = aws_iam_role.execution
  id = "game-analytics-execution-role"
}

resource "aws_iam_role" "execution" {
  name        = "game-analytics-execution-role"
  description = "Allows ECS tasks to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "game-analytics"
  }
}


# AWS-managed ECS execution policy

import {
  to = aws_iam_role_policy_attachment.execution
  id = "game-analytics-execution-role/arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# Read RAWG API key from SSM Parameter Store

import {
  to = aws_iam_role_policy.execution_ssm
  id = "game-analytics-execution-role:game-analytics-ssm-read"
}

resource "aws_iam_role_policy" "execution_ssm" {
  name = "game-analytics-ssm-read"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/game-analytics/rawg-api-key"
        ]
      }
    ]
  })
}


# ECS task role

import {
  to = aws_iam_role.task
  id = "game-analytics-task-role"
}

resource "aws_iam_role" "task" {
  name        = "game-analytics-task-role"
  description = "Allows ECS tasks to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "game-analytics"
  }
}


# Pipeline access to S3 bucket

import {
  to = aws_iam_role_policy.task_s3
  id = "game-analytics-task-role:game-analytics-task-rolePolicy"
}

resource "aws_iam_role_policy" "task_s3" {
  name = "game-analytics-task-rolePolicy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn
        ]
      }
    ]
  })
}


# Scheduler role

import {
  to = aws_iam_role.scheduler
  id = "game-analytics-scheduler-role"
}

resource "aws_iam_role" "scheduler" {
  name        = "game-analytics-scheduler-role"
  description = "Role for eventbridge scheduler to run game analytics pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "game-analytics"
  }
}


# Permissions to run ECS tasks and pass IAM roles

import {
  to = aws_iam_role_policy.scheduler_ecs
  id = "game-analytics-scheduler-role:game-analytics-scheduler-rolePolicy"
}

resource "aws_iam_role_policy" "scheduler_ecs" {
  name = "game-analytics-scheduler-rolePolicy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunTask"
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          "${aws_ecs_task_definition.pipeline.arn_without_revision}:*"
        ]
      },
      {
        Sid    = "TagTask"
        Effect = "Allow"
        Action = [
          "ecs:TagResource"
        ]
        Resource = [
          "arn:aws:ecs:eu-central-1:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.pipeline.name}/*"
        ]
      },
      {
        Sid    = "PassRoles"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.execution.arn,
          aws_iam_role.task.arn
        ]
      }
    ]
  })
}


# EventBridge alerting role

import {
  to = aws_iam_role.alerting
  id = "Amazon_EventBridge_Invoke_Sns_473456404"
}

resource "aws_iam_role" "alerting" {
  name = "Amazon_EventBridge_Invoke_Sns_473456404"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceArn"     = aws_cloudwatch_event_rule.task_failed.arn
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Project = "game-analytics"
  }
}


# Publish policy (customer managed)
import {
  to = aws_iam_policy.alerting_publish
  id = "arn:aws:iam::649473075374:policy/service-role/Amazon_EventBridge_Invoke_Sns_473456404"
}

resource "aws_iam_policy" "alerting_publish" {
  name = "Amazon_EventBridge_Invoke_Sns_473456404"
  path = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.email_alert.arn]
      }
    ]
  })

  tags = {
    Project = "game-analytics"
  }
}


# Publish policy attachment
import {
  to = aws_iam_role_policy_attachment.alerting_publish
  id = "Amazon_EventBridge_Invoke_Sns_473456404/arn:aws:iam::649473075374:policy/service-role/Amazon_EventBridge_Invoke_Sns_473456404"
}

resource "aws_iam_role_policy_attachment" "alerting_publish" {
  role       = aws_iam_role.alerting.name
  policy_arn = aws_iam_policy.alerting_publish.arn
}
