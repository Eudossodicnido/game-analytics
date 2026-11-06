import {
  to = aws_scheduler_schedule.monthly_run
  identity = {
    group_name = "default"
    name       = "game-analytics-monthly"
  }
}

resource "aws_scheduler_schedule" "monthly_run" {
  name                         = "game-analytics-monthly"
  group_name                   = "default"
  state                        = "ENABLED"
  action_after_completion      = "NONE"
  schedule_expression          = "cron(00 00 15 * ? *)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_ecs_cluster.pipeline.arn
    role_arn = "arn:aws:iam::649473075374:role/game-analytics-scheduler-role"

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.pipeline.arn
      launch_type         = "FARGATE"
      task_count          = 1
      propagate_tags      = "TASK_DEFINITION"

      # Preserve the existing tag without a value.
      tags = {
        Project = ""
      }

      network_configuration {
        assign_public_ip = true
        subnets          = ["subnet-0a3ebbbf9a4ed1e04"]
        security_groups  = ["sg-01411eed706fc960e"]
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = 86400
      maximum_retry_attempts       = 185
    }
  }
}