output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.ai_bot_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}