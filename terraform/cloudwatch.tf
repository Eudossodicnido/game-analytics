#pipeline_logs
import {
  to = aws_cloudwatch_log_group.pipeline
  identity = {
    name = "/ecs/game-analytics"
  }
}

resource "aws_cloudwatch_log_group" "pipeline" {
  name                        = "/ecs/game-analytics"
  log_group_class             = "STANDARD"
  retention_in_days           = 0
  deletion_protection_enabled = false
  tags = {
    Project = "game-analytics"
  }
}