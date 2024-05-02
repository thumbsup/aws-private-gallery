const AWS = require('@aws-sdk/client-ssm')
const cloudfront = require('aws-cloudfront-sign')

exports.getKeyPair = function () {
  const ssm = new AWS.SSM()
  const params = {
    Names: [
      'cloudfront_keypair_id',
      'cloudfront_private_key'
    ],
    WithDecryption: true
  }
  return new Promise((resolve, reject) => {
    ssm.getParameters(params, (err, data) => {
      if (err) {
        reject(err)
      } else {
        resolve({
          keyPairId: data.Parameters[0].Value,
          privateKey: data.Parameters[1].Value
        })
      }
    })
  })
}

exports.sign = function (domain, sessionDuration, keypairId, privateKey) {
  // signed cookies are effectively a base64-encoded IAM policy
  // with a cryptographic signature to prove who issued the policy
  const signedCookies = cloudfront.getSignedCookies(`https://${domain}/*`, {
    expireTime: new Date().getTime() + (sessionDuration * 1000),
    keypairId,
    privateKeyString: privateKey
  })
  // return cookies as a hash for Lambda
  return cookiesHash(
    domain,
    signedCookies['CloudFront-Policy'],
    signedCookies['CloudFront-Signature'],
    signedCookies['CloudFront-Key-Pair-Id']
  )
}

exports.reset = function (domain) {
  return cookiesHash(domain, '', '', '')
}

function cookiesHash (domain, policy, signature, keypairId) {
  // we use a combination of lower/upper case cookie names
  // because we need to send multiple cookies
  // but the AWS API requires all headers in a single object!
  const options = `Domain=${domain}; Path=/; Secure; HttpOnly`
  return {
    'Set-Cookie': `CloudFront-Policy=${policy}; ${options}`,
    'SEt-Cookie': `CloudFront-Signature=${signature}; ${options}`,
    'SET-Cookie': `CloudFront-Key-Pair-Id=${keypairId}; ${options}`
  }
}
