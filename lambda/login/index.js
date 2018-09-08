const callback = require('./lib/controllers/callback')
const logout = require('./lib/controllers/logout')

// Handler that gets called on every invocation
exports.handler = (event, context, done) => {
  // Route based on the HTTP call
  if (event.path === '/api/callback') {
    callback.handle(event, done)
  } else if (event.path === '/api/logout') {
    logout.handle(event, done)
  } else {
    done(null, errorResponse(404, `Not found: ${event.path}`))
  }
}

function errorResponse (code, message) {
  return {
    statusCode: code,
    body: message,
    headers: {},
    isBase64Encoded: false
  }
}
