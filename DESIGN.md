# Technical design

There are 4 main components involved.

- [S3 bucket](https://aws.amazon.com/s3) to store the website (HTML, CSS, media...)
- [CloudFront](https://aws.amazon.com/cloudfront) to provide caching and edge-authentication
- [Cognito](https://aws.amazon.com/cognito) to manage users and authentication
- [Lambda](https://aws.amazon.com/lambda) to validate Cognito tokens and create [CloudFront signed cookies](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-cookies.html)

## Login flow

```mermaid
sequenceDiagram

    participant Browser
    participant CloudFront
    participant S3
    participant Lambda
    participant Cognito
    participant ParameterStore

    Note left of Browser: Try getting a file
    Browser->>+CloudFront: Get file
    Note right of CloudFront: No cookie
    CloudFront->>+S3: Error page
    S3->>-CloudFront: 403.html
    CloudFront->>-Browser: HTML

    Note left of Browser: JavaScript redirect, start OAuth flow
    Browser->>+Cognito: Get login page
    Cognito->>-Browser: HTML
    Browser->>+Cognito: Post credentials
    Note right of Cognito: Validate login
    Cognito->>-Browser: HTTP 302
    Browser->>+CloudFront: callback?code=123
    CloudFront->>+Lambda: call
    Note right of Lambda: Initialise lambda
    opt Only once
      Lambda->>+Cognito: Get JWKS
      Cognito->>-Lambda: Key set
      Lambda->>+ParameterStore: Get CloudFront private key
      ParameterStore->>-Lambda: Private key
    end
    Note right of Lambda: Get Cognito JWT
    Lambda->>+Cognito: Exchange code for JWT
    Cognito->>-Lambda: JWT
    Note right of Lambda: Validate JWT token signature
    Lambda->>-CloudFront: HTTP 302 + Signed cookies
    CloudFront->>-Browser: Response

    Note left of Browser: Try getting the file again
    Browser->>+CloudFront: Get file
    Note right of CloudFront: Validate cookie, all good
    CloudFront->>+S3: Proxy to origin
    S3->>-CloudFront: File contents
    CloudFront->>-Browser: File contents
```

## Logout flow

```mermaid
sequenceDiagram

    participant Browser
    participant CloudFront
    participant Lambda
    participant Cognito

    Note left of Browser: Users chooses to logout
    Browser->>+CloudFront: /api/logout
    CloudFront->>+Lambda: call
    Note right of Lambda: Remove CloudFront cookies
    Lambda->>-Browser: HTTP 302 removing cookies

    Note left of Browser: Follow the redirect
    Browser->>+Cognito: /logout
    Note right of Cognito: Remove Cognito cookies
    Cognito->>-Browser: 302 removing cookies

    Note left of Browser: Follow the redirect
    Browser->>+Cognito: /login
    Cognito->>-Browser: Login page
    Note left of Browser: Render the standard Cognito login page
```
