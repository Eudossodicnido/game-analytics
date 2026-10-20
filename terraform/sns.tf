#Topic
import {
  to = aws_sns_topic.email_alert
  identity = {
    "arn" = "arn:aws:sns:eu-central-1:649473075374:game-analytics-alerts"
  }
}

resource "aws_sns_topic" "email_alert" {
  name         = "game-analytics-alerts"
  display_name = "game-analytics-alerts"
}


#Policy
import {
  to = aws_sns_topic_policy.topic_policy
  identity = {
    "arn" = "arn:aws:sns:eu-central-1:649473075374:game-analytics-alerts"
  }
}


resource "aws_sns_topic_policy" "topic_policy" {
  arn    = aws_sns_topic.email_alert.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  version   = "2008-10-17"
  policy_id = "__default_policy_ID"

  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"

    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [aws_sns_topic.email_alert.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid     = "PublishEventsToMyTopic"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.email_alert.arn]
  }
}



#Subcription

import {
  to = aws_sns_topic_subscription.email_alert
  identity = {
    "arn" = "arn:aws:sns:eu-central-1:649473075374:game-analytics-alerts:8d1baacd-155b-468d-a1f5-dd9f625f3ac3"
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.email_alert.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
