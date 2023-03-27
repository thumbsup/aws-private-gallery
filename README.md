# AWS private static gallery

> One-click deployment of your static Thumbsup gallery to AWS

Features:

- Custom domain name
- CDN caching
- HTTPS / TLS
- User authentication

It is designed to have:

- `minimal infrastructure`: no servers or databases to maintain
- `low cost`: the website is served from cache (even private content!)
- `invite-only`: you can control who has access
- `flexible`: can login with email/password, or using social logins
- `self managed`: users can reset their own passwords

## Intro

There are 4 main AWS components involved:

- [S3 bucket](https://aws.amazon.com/s3) to store the website (HTML, CSS, media...)
- [CloudFront](https://aws.amazon.com/cloudfront) to provide caching and edge-authentication
- [Cognito](https://aws.amazon.com/cognito) to manage users and authentication
- [Lambda](https://aws.amazon.com/lambda) to validate Cognito tokens and create [CloudFront signed cookies](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-cookies.html)

See [DESIGN.md](DESIGN.md) for more details about how the site is setup.

This repo is meant to provide a bootstrap for your private gallery.
Cognito is very flexible, and you will probably want to tweak a few settings once deployed.
For example, you might want to:

- customise the login page with a logo
- allow self sign-ups with an approval workflow
- enable social logins with Google or Facebook

## Setup

### 1. Configure this repo

Before you setup the gallery, you will need to clone and adjust the following files:

| Template | Expected name | Content |
|----------|---------------|---------|
| [lambda/whitelist/emails.js.example](lambda/whitelist/emails.js.example) | `lambda/whitelist/emails.js` | List of email addresses that can access the gallery |
| [infra/terraform.tfvars.example](infra/terraform.tfvars.example) | `infra/terraform.tfvars` | S3 bucket name, domain name... |
| [infra/backend.tf.example](infra/backend.tf.example) | `infra/backend.tf` | Terraform state storage |
| [infra/templates/email-invite.html.example](infra/templates/email-invite.html.example) | `infra/templates/email-invite.html` | Email template |

### 2. Create the TLS certificate for your domain

Create a TLS certificate in [AWS Certificate Manager](https://console.aws.amazon.com/acm).
Regardless of any other settings, the certificate must be created  in `us-east-1` (North Virginia).
Follow the prompts to validate the domain by email or DNS.

### 3. Build the Lambda functions

The login/whitelist functions are written in [Node.js](https://nodejs.org),
built and packaged inside [Docker](https://www.docker.com).
The following will create the ZIP files which are needed for the next step.

```bash
cd lambda
./build.sh
```

### 4. Create a CloudFront key pair

Authentication relies on cookies signed with a key pair.
You must generate a new one locally:

``` bash
cd infra
openssl genrsa -out private_key.pem 2048
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

These keys will be deployed as part of the infrastructure. AWS recommends rotating them every 3 months.

Note: the values are cached by the Lambda function (in memory) to speed up invocation.
When you rotate the key pair, the old value will still be used until the next **Lambda cold start**.
You can re-deploy the Lambda function to force a cold-start.

### 5. Deploy infrastructure

The whole infrastructure is written as [Terraform](https://www.terraform.io/) templates.
First, authenticate against AWS with the [AWS CLI](https://aws.amazon.com/cli):

- run `aws configure` and enter the access key and secret key
- if you saved your credentials as a non-default profile, run `export AWS_PROFILE=profile_name`
- select the target AWS region using `export AWS_REGION=ap-southeast-2`

Then simply run the following commands to create the infrastructure:

```bash
cd infra
terraform apply
```

If you make any subsequent changes, simply re-run `terraform apply` to apply the update.
The Terraform code relies on `public_key.pem` and `private_key.pem` existing in the `infra` folder.

### 6. Create users

The final step is to create a user so you can go through the login page.

- Navigate to https://console.aws.amazon.com/cognito
- Click "Browse your user pools"
- Select the pool that was created by Terraform
- Click "Users and groups", then "Create user"
- Provide an email address and temporary password

### That's it!

You should now be able to browse to https://your-gallery.com and be prompted to login.

It's time to upload your gallery to the bucket defined in `infra/terraform.tfvars`.
The simplest way is using the CLI with `aws s3 sync`, e.g.

```bash
aws s3 sync ./gallery s3://my-gallery
```
