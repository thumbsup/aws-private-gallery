resource "aws_api_gateway_rest_api" "login" {
  name        = "CloudFrontCookies"
  description = "Exchange Cognito auth token for CloudFront cookies"
}

resource "aws_api_gateway_resource" "callback" {
  rest_api_id = "${aws_api_gateway_rest_api.login.id}"
  parent_id   = "${aws_api_gateway_rest_api.login.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "callback" {
  rest_api_id   = "${aws_api_gateway_rest_api.login.id}"
  resource_id   = "${aws_api_gateway_resource.callback.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = "${aws_api_gateway_rest_api.login.id}"
  resource_id             = "${aws_api_gateway_method.callback.resource_id}"
  http_method             = "${aws_api_gateway_method.callback.http_method}"
  uri                     = "${aws_lambda_function.login.invoke_arn}"
  content_handling        = "CONVERT_TO_TEXT"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
}

resource "aws_api_gateway_deployment" "login" {
  depends_on  = ["aws_api_gateway_integration.lambda"]
  rest_api_id = "${aws_api_gateway_rest_api.login.id}"
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.login.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.login.execution_arn}/GET/*"
}
