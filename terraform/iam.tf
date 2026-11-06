
# ============================================================
# IAM — Game Analytics Pipeline
# ============================================================
# Import existing IAM resources without changing AWS.
#
# Managed:
# - ECS Execution Role
# - ECS Task Role
# - EventBridge Scheduler Role
# - EventBridge Alerting Role
#
# Excluded:
# - game-analytics-terraform-role
# ============================================================


# ------------------------------------------------------------
# 1. ECS EXECUTION ROLE
# ------------------------------------------------------------

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
          "arn:aws:ssm:eu-central-1:649473075374:parameter/game-analytics/rawg-api-key"
        ]
      }
    ]
  })
}


# ------------------------------------------------------------
# 2. ECS TASK ROLE
# ------------------------------------------------------------

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
          "arn:aws:s3:::rawg-pipeline-videogames-649473075374-eu-central-1-an/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::rawg-pipeline-videogames-649473075374-eu-central-1-an"
        ]
      }
    ]
  })
}


# ------------------------------------------------------------
# 3. EVENTBRIDGE SCHEDULER ROLE
# ------------------------------------------------------------

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
          "arn:aws:ecs:eu-central-1:649473075374:task-definition/game-analytics:*"
        ]
      },
      {
        Sid    = "TagTask"
        Effect = "Allow"
        Action = [
          "ecs:TagResource"
        ]
        Resource = [
          "arn:aws:ecs:eu-central-1:649473075374:task/game-analytics-cluster/*"
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


# ------------------------------------------------------------
# 4. EVENTBRIDGE ALERTING ROLE
# ------------------------------------------------------------

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
            "aws:SourceAccount" = nonsensitive(var.account_id)
          }
        }
      }
    ]
  })
}


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
}


import {
  to = aws_iam_role_policy_attachment.alerting_publish
  id = "Amazon_EventBridge_Invoke_Sns_473456404/arn:aws:iam::649473075374:policy/service-role/Amazon_EventBridge_Invoke_Sns_473456404"
}

resource "aws_iam_role_policy_attachment" "alerting_publish" {
  role       = aws_iam_role.alerting.name
  policy_arn = aws_iam_policy.alerting_publish.arn
}
