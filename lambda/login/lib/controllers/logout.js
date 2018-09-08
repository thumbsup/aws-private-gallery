const cloudfront = require('../cloudfront')
const config = require('../config')

exports.handle = function (event, callback) {
  // Headers to delete all CloudFront cookies
  const headers = cloudfront.reset(config.websiteDomain)

  // Redirect to the Cognito logout URL to clear the cognito session too
  const params = [
    'response_type=code',
    'scope=openid+email+aws.cognito.signin.user.admin',
    `client_id=${config.clientId}`,
    `redirect_uri=https://${config.websiteDomain}/api/callback`
  ]
  headers['Location'] = `${config.cognitoApi}/logout?` + params.join('&')

  // Return the 302 redirect
  callback(null, {
    statusCode: 302,
    body: 'Logout successful',
    headers: headers,
    isBase64Encoded: false
  })
}
