const whitelist = require('emails.js')

exports.handler = function (event, context) {
  const signupEmail = event.request.userAttributes.email
  if (whitelist.indexOf(signupEmail) === -1) {
    context.done(new Error('You do not have access'), event)
  } else {
    context.done(null, event)
  }
}
