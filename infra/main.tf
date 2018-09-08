# target region where the stack will be deployed
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
}

# us-east-1 instance
# where CloudFront TLS certs are stored
provider "aws" {
  region                  = "us-east-1"
  alias                   = "useast1"
  shared_credentials_file = "~/.aws/credentials"
}

data "aws_caller_identity" "current" {}

locals {
  cognito_oauth_server = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
  cognito_login_url    = "${local.cognito_oauth_server}/oauth2/authorize?response_type=code&client_id=${aws_cognito_user_pool_client.client.id}&scope=openid+email+aws.cognito.signin.user.admin&redirect_uri=https://${var.website_domain}/api/callback"
  cognito_logout_url   = "${local.cognito_oauth_server}/logout?client_id=${aws_cognito_user_pool_client.client.id}&logout_uri=https://${var.website_domain}/api/logout"
}

output "gallery_url" {
  value = "https://${var.website_domain}"
}

output "login_url" {
  value = "${local.cognito_login_url}"
}

output "logout_url" {
  value = "${local.cognito_logout_url}"
}
