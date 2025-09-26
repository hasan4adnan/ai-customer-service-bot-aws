resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "ai-customer-service-bot-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = aws_lambda_function.ai_bot.function_name
  }

  alarm_description = "An error occurred in the Lambda function!"
  alarm_actions     = [aws_sns_topic.alerts.arn]
}
