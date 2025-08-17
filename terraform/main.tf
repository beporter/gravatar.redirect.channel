
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      terraform = true
      repository = "gravatar.redirect.channel"
      environment = "production"
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "gravatar_lambda" {
  function_name = "gravatar_redirect"
  description = "Takes an email address, and returns the lowercase > SHA256 > base64 string."

  role          = aws_iam_role.iam_for_lambda.arn

  filename      = "lambda.py"
  source_code_hash =  filebase64sha256("lambda.py")
  architectures = ["arm64"]
  runtime = "python3.13"

  environment {
    variables = {
      foo = "bar"
    }
  }

  tags {

  }
}

resource "aws_lambda_function_url" "gravatar_lambda_url" {
  function_name      = gravatar_lambda.arn
  authorization_type = "NONE"
  cors {
    allow_origins     = ["gravatar,redirect.channel"]
    allow_methods     = ["POST"]
    max_age = 5
  }
}

# resource "aws_lambda_function_url" "test_live" {
#   function_name      = aws_lambda_function.test.function_name
#   qualifier          = "my_alias"
#   authorization_type = "AWS_IAM"

#   cors {
#     allow_credentials = true
#     allow_origins     = ["*"]
#     allow_methods     = ["*"]
#     allow_headers     = ["date", "keep-alive"]
#     expose_headers    = ["keep-alive", "date"]
#     max_age           = 86400
#   }
# }

output "lambda_url" {
  value = gravatar_lambda_url.function_url
}
