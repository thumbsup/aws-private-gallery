const assert = require('assert')
const config = {}

// Client ID of the Cognito OAuth application
// e.g. "123456"
config.clientId = process.env['CLIENT_ID']
assert(config.clientId, 'Please set CLIENT_ID')

// Cognito OAuth API base URL
// e.g. https://your-domain.auth.ap-southeast-2.amazoncognito.com
config.cognitoApi = process.env['COGNITO_API']
assert(config.cognitoApi, 'Please set COGNITO_API')

// Cognito ISS
// e.g. https://cognito-idp.us-east-2.amazonaws.com/123456789
config.cognitoIss = process.env['COGNITO_ISS']
assert(config.cognitoIss, 'Please set COGNITO_ISS')

// Session duration once the user is logged-in, in seconds
// e.g. 86400 = 1 day
config.sessionDuration = parseInt(process.env['SESSION_DURATION'], 10)
assert(config.sessionDuration, 'Please set SESSION_DURATION')

// Target website domain
// e.g. "mywebsite.com"
config.websiteDomain = process.env['WEBSITE_DOMAIN']
assert(config.websiteDomain, 'Please set WEBSITE_DOMAIN')

module.exports = config
