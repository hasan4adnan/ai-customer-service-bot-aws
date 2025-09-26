provider "aws" {
  region = var.region
}

# DynamoDB
resource "aws_dynamodb_table" "conversation_history" {
  name         = "conversation_history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}

# SNS
resource "aws_sns_topic" "alerts" {
  name = "ai-bot-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "<YOUR_ALERT_EMAIL_ADDRESS>" # Put your alert email address here
}

# CloudWatch
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/ai-customer-service-bot"
  retention_in_days = 14
}

# IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Attachments
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

# Lambda
resource "aws_lambda_function" "ai_bot" {
  function_name = "ai-customer-service-bot"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  timeout = 15  # Lambda timeout in seconds
  memory_size = 256  # Optionally increase memory if needed

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}


# REST API
resource "aws_api_gateway_rest_api" "ai_bot_api" {
  name        = "ai-customer-service-bot-api"
  description = "API Gateway for AI Customer Service Bot"
}

# /ask endpoint
resource "aws_api_gateway_resource" "ask_resource" {
  rest_api_id = aws_api_gateway_rest_api.ai_bot_api.id
  parent_id   = aws_api_gateway_rest_api.ai_bot_api.root_resource_id
  path_part   = "ask"
}

# POST method
resource "aws_api_gateway_method" "ask_post" {
  rest_api_id   = aws_api_gateway_rest_api.ai_bot_api.id
  resource_id   = aws_api_gateway_resource.ask_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ai_bot_api.id
  resource_id             = aws_api_gateway_resource.ask_resource.id
  http_method             = aws_api_gateway_method.ask_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ai_bot.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "ai_bot_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ai_bot_api.id

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

# Stage (dev)
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.ai_bot_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.ai_bot_api.id
  stage_name    = "dev"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_bot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ai_bot_api.execution_arn}/*/*"
}
