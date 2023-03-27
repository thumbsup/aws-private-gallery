resource "aws_lambda_function" "login" {
  filename         = "../lambda/login.zip"
  function_name    = "cloudfront-cookies"
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("../lambda/login.zip"))}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  environment {
    variables = {
      CLIENT_ID        = "${aws_cognito_user_pool_client.client.id}"
      COGNITO_API      = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
      COGNITO_ISS      = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.pool.id}"
      SESSION_DURATION = 86400
      WEBSITE_DOMAIN   = "${var.website_domain}"
    }
  }
}

resource "aws_lambda_function" "whitelist" {
  filename         = "../lambda/whitelist.zip"
  function_name    = "cognito-whitelist"
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("../lambda/whitelist.zip"))}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
}

resource "aws_lambda_permission" "cognito_whitelist" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.whitelist.function_name}"
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "${aws_cognito_user_pool.pool.arn}"

  # source_arn    = "arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.pool.id}"
  # qualifier      = "${aws_lambda_alias.test_alias.name}"
  # source_account = "${data.aws_caller_identity.current.account_id}"
}

# Assume IAM role for the lambda function
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume.json}"
}

# Access to CloudWatch, using one of the built-in policies
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_access" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# Access to get SSM Parameter Store values
resource "aws_iam_role_policy" "ssm_read" {
  name   = "lambda_ssm_read"
  role   = "${aws_iam_role.iam_for_lambda.id}"
  policy = "${data.aws_iam_policy_document.lambda_access.json}"
}

# Trust policy under which the Lambda runs
# This has to be separate from any additional "non trust" policies
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Policy that grants access to AWS SSM
data "aws_iam_policy_document" "lambda_access" {
  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    actions = ["ssm:GetParameters"]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/cloudfront_keypair_id",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/cloudfront_private_key",
    ]
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}
