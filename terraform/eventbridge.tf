# EventBridge
# Rule that matches failed pipeline tasks, and its SNS target.

# Rule
import {
  to = aws_cloudwatch_event_rule.task_failed
  identity = {
    name = "game-analytics-task-failed"
  }
}

resource "aws_cloudwatch_event_rule" "task_failed" {
  name           = "game-analytics-task-failed"
  event_bus_name = "default"
  state          = "ENABLED"
  tags = {
    Project = "game-analytics"
  }
  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail-type" : ["ECS Task State Change"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.pipeline.arn],
      "lastStatus" : ["STOPPED"],
      "$or" : [{
        "stopCode" : [{
          "anything-but" : "EssentialContainerExited"
        }]
        }, {
        "containers" : {
          "exitCode" : [{
            "anything-but" : 0
          }]
        }
      }]
    }
  })
}

# Target (separate resource from the rule)
import {
  to = aws_cloudwatch_event_target.task_failed_alert
  identity = {
    event_bus_name = "default"
    rule           = "game-analytics-task-failed"
    target_id      = "Idfb13f72e-734a-426b-bcce-fc22817f6c9e"
  }
}

resource "aws_cloudwatch_event_target" "task_failed_alert" {
  rule           = aws_cloudwatch_event_rule.task_failed.name
  event_bus_name = "default"
  target_id      = "Idfb13f72e-734a-426b-bcce-fc22817f6c9e"
  arn            = aws_sns_topic.email_alert.arn
  role_arn       = aws_iam_role.alerting.arn
  # Input = "Matched event" is the default, so no input/input_transformer.
  # No DLQ, no additional parameters.
}
