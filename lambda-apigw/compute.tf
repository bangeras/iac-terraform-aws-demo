# Lambda function
resource "aws_lambda_function" "payment_api_lambda_function" {
  function_name = "payment_api-lambda-function"
  runtime       = "python3.8"
  handler       = "payment_lambda_function.lambda_handler"
  filename      = "./lambda_functions/function.zip"
  role          = aws_iam_role.payment_lambda_function_execution_role.arn
}

# API Gateway
resource "aws_api_gateway_rest_api" "payment_api" {
  name        = "${var.vpc_suffix}-payment_api"
  description = "Payment API Gateway integrated with Lambda functions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "payment_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  parent_id   = aws_api_gateway_rest_api.payment_api.root_resource_id
  path_part   = "payment"
}

# API Gateway Method
resource "aws_api_gateway_method" "payment_api_resource_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api.id
  resource_id   = aws_api_gateway_resource.payment_api_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Lambda Integration with API Gateway
resource "aws_api_gateway_integration" "payment_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api.id
  resource_id             = aws_api_gateway_resource.payment_api_resource.id
  http_method             = aws_api_gateway_method.payment_api_resource_method.http_method
  integration_http_method = "POST" # Set your desired HTTP method
  # The type of integration with the specified backend. The valid value is
  #   http or http_proxy: for integration with an HTTP backend
  #   aws_proxy: for integration with AWS Lambda functions;
  #   aws: for integration with AWS Lambda functions or other AWS services, such as Amazon DynamoDB, Amazon Simple Notification Service or Amazon Simple Queue Service;
  #   mock: for integration with API Gateway without invoking any backend.

  type = "AWS_PROXY"
  uri  = aws_lambda_function.payment_api_lambda_function.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "payment_api_deployment" {
  depends_on = [aws_api_gateway_integration.payment_api_integration]

  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  stage_name  = "dev" # Set your desired stage name
}

# Used to give an external source (like an API Gateway, EventBridge Rule, SNS, or S3) permission to access the Lambda function
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_api_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: https://repost.aws/questions/QUizsg_qznQLWKtqUD8Ruszw/api-gateway-lacks-permissions-to-trigger-lambda-when-made-by-terraform
  source_arn = "${aws_api_gateway_rest_api.payment_api.execution_arn}/*/*/*"
}


# API Gateway Resource
resource "aws_api_gateway_resource" "payment_api_notification_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  parent_id   = aws_api_gateway_rest_api.payment_api.root_resource_id
  path_part   = "payment_notification"
}

# API Gateway Method
resource "aws_api_gateway_method" "payment_api_notification_resource_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api.id
  resource_id   = aws_api_gateway_resource.payment_api_notification_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Lambda Integration with API Gateway
resource "aws_api_gateway_integration" "payment_api_notification_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api.id
  resource_id             = aws_api_gateway_resource.payment_api_notification_resource.id
  http_method             = aws_api_gateway_method.payment_api_notification_resource_method.http_method
  integration_http_method = "POST" # Set your desired HTTP method
  # The type of integration with the specified backend. The valid value is
  #   http or http_proxy: for integration with an HTTP backend
  #   aws_proxy: for integration with AWS Lambda functions;
  #   aws: for integration with AWS Lambda functions or other AWS services, such as Amazon DynamoDB, Amazon Simple Notification Service or Amazon Simple Queue Service;
  #   mock: for integration with API Gateway without invoking any backend.

  type = "AWS"
  uri  = aws_lambda_function.payment_api_lambda_function.invoke_arn
}