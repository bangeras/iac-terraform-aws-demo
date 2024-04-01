# IAM Role for Lambda Execution
resource "aws_iam_role" "payment_lambda_function_execution_role" {
  name = "payment-lambda-function-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
