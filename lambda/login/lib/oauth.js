const axios = require('axios')

class OAuthServer {
  constructor (options) {
    this.api = options.api
    this.iss = options.iss
    this.clientId = options.clientId
    this.redirectUri = options.redirectUri
  }
  getJWKS () {
    return axios.get(`${this.iss}/.well-known/jwks.json`)
                .then(res => res.data)
  }
  getToken (authCode) {
    const postData = `grant_type=authorization_code` +
      `&client_id=${this.clientId}` +
      `&code=${authCode}` +
      `&redirect_uri=${this.redirectUri}`
    return axios.post(`${this.api}/oauth2/token`, postData)
                .then(res => res.data.id_token)
  }
}

module.exports = OAuthServer
