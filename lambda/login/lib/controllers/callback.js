const cloudfront = require('../cloudfront')
const config = require('../config')
const jwt = require('../jwt')
const OAuthServer = require('../oauth')

const oauthServer = new OAuthServer({
  api: config.cognitoApi,
  iss: config.cognitoIss,
  clientId: config.clientId,
  redirectUri: `https://${config.websiteDomain}/api/callback`
})

// These 2 functions can be cached
// The first call will fire off the new Promise
// Subsequent invocations can simply use the same promise
const keypairPromise = memoise(() => cloudfront.getKeyPair())
const jwksPromise = memoise(() => oauthServer.getJWKS())

exports.handle = function (event, callback) {
  const qs = event.queryStringParameters || {}

  // Check for errors
  if (qs.error) {
    console.log(`Error: ${qs.error} ${qs.error_description}`)
    return callback(null, errorResponse(403, `Authentication error: ${qs.error_description}`))
  }

  // Check that we have the required OAuth2 authorisation code
  if (!qs.code) {
    return callback(null, errorResponse(400, 'Missing OAuth2 code'))
  }

  // Start the validation flow
  Promise.all([
    keypairPromise(),
    jwksPromise(),
    oauthServer.getToken(qs.code)
  ]).then(results => {
    const keypair = results[0]
    const jwks = results[1]
    const token = results[2]
    jwt.verify(token, jwks)
    const headers = cloudfront.sign(config.websiteDomain, config.sessionDuration, keypair.keyPairId, keypair.privateKey)
    callback(null, redirect(headers))
  })
  .catch(err => {
    if (err.response) {
      console.error('HTTP error', err.response.status, err.response.data)
    } else {
      console.error('Unknown error', err)
    }
    callback(null, errorResponse(500, 'Authentication failed'))
  })
}

function memoise (fn) {
  var value = null
  return function () {
    if (!value) {
      const args = Array.prototype.slice.call(arguments)
      value = fn.apply(fn, args)
    }
    return value
  }
}

function errorResponse (code, message) {
  return {
    statusCode: code,
    body: `<h1>Unexpected error</h1><p>${message}</p><p>Click <a href="/">here</a> to go back to the home page</p>`,
    headers: {
      'Content-Type': 'text/html'
    },
    isBase64Encoded: false
  }
}

function redirect (headers) {
  headers['Location'] = '/'
  return {
    statusCode: 302,
    body: 'Authentication successful',
    headers: headers,
    isBase64Encoded: false
  }
}
