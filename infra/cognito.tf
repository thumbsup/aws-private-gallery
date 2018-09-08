resource "aws_cognito_user_pool" "pool" {
  name                       = "${var.project_name}"
  mfa_configuration          = "OFF"
  username_attributes        = ["email"]
  auto_verified_attributes   = ["email"]
  sms_verification_message   = "Your verification code is {####}."
  sms_authentication_message = "Your authentication code is {####}."

  admin_create_user_config {
    allow_admin_create_user_only = true
    unused_account_validity_days = 7

    invite_message_template {
      email_subject = "Welcome to ${var.project_name}"
      email_message = "${file("templates/email-invite.html")}"
      sms_message   = "Your username is {username} and temporary password is {####}."
    }
  }

  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  email_configuration {
    reply_to_email_address = "${var.contact_email}"
  }

  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  lambda_config {
    pre_sign_up        = "${aws_lambda_function.whitelist.arn}"
    pre_authentication = "${aws_lambda_function.whitelist.arn}"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${replace(var.website_domain, ".", "-")}"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "client"
  user_pool_id                         = "${aws_cognito_user_pool.pool.id}"
  callback_urls                        = ["https://${var.website_domain}/api/callback"]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin", "openid", "email", "profile"]
  read_attributes                      = ["email", "email_verified"]
  supported_identity_providers         = ["COGNITO"]
}
