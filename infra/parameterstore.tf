resource "aws_ssm_parameter" "keypair_id" {
  name        = "cloudfront_keypair_id"
  description = "ID of the public key in CloudFront"
  type        = "String"
  value.      = aws_cloudfront_public_key.cookie_signer.id
}

resource "aws_ssm_parameter" "private_key" {
  name        = "cloudfront_private_key"
  description = "Private key for signing CloudFront cookies"
  type        = "SecureString"
  value       = file("private_key.pem")
}
