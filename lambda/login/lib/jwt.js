const jwt = require('jsonwebtoken')
const jwkToPem = require('jwk-to-pem')

exports.verify = function (token, keySet) {
  // Decode the JWT token to find the JWK ID
  const decoded = jwt.decode(token, {complete: true})
  console.log(`Received JWT user=${decoded.payload['cognito:username']}, email=${decoded.payload['email']}`)
  // Verify the JWT
  const pem = getMatchingPem(keySet, decoded.header.kid)
  jwt.verify(token, pem, { algorithms: ['RS256'] })
  console.log('JWT verified successfully')
}

function getMatchingPem (keySet, keyId) {
  for (var i = 0; i < keySet.keys.length; i++) {
    if (keySet.keys[i].kid === keyId) {
      return jwkToPem(keySet.keys[i])
    }
  }
  return null
}
