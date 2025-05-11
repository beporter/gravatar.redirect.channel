provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      terraform = true
      project = grc
      repository = "https://github.com/beporter/gravatar.redirect.channel/"
      environment = production
    }
  }
}

// Set up IAM permissions
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Define the lambda payload.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/"
  output_path = "${path.module}/../dist/lambda_function_payload.zip"
}

# Set up the lambda and routing to it.
resource "aws_lambda_function" "gravatarize_lambda" {
  function_name = "gravatarize"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "lambda-api"
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.my_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# Static HTML hosting on S3.

# S3 Bucket for static site
resource "aws_s3_bucket" "static_site" {
  bucket = var.site_domain_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# Generate index.html with lambda URL
data "template_file" "index_html" {
  template = file("${path.module}/web/index.html.tftpl")

  vars = {
    lambda_url = aws_apigatewayv2_api.lambda_api.api_endpoint
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "index.html"
  content_type = "text/html"
  content = data.template_file.index_html.rendered
  acl    = "public-read"
}

# Route53 domain setup
data "aws_route53_zone" "main" {
  name         = var.domain_zone
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.site_domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.static_site.website_domain
    zone_id                = "Z3AQBSTGFYJSTF" # S3 website hosting zone ID (us-east-1)
    evaluate_target_health = false
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = var.site_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "S3SiteCert"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Budget alerts
resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email # e.g. "your-email@example.com"
}

resource "aws_budgets_budget" "monthly_limit" {
  name              = "LambdaCostLimit"
  budget_type       = "COST"
  limit_amount      = var.monthly_dollar_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  cost_filter {
    name = "Service"
    values = [
      "AWS Lambda"
    ]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 90
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }
}
