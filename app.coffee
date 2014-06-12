express = require 'express'
logfmt = require 'logfmt'
request = require 'request'

missing = []

for key in ['USERNAME', 'PASSWORD', 'SLACK_APP', 'SLACK_CHANNEL', 'SLACK_TOKEN']
  missing.push key unless key of process.env

throw "Missing environment variables: #{missing.join ', '}" if missing.length

app = express()

app.use logfmt.requestLogger()

app.use express.basicAuth (username, password) ->
  username is process.env.USERNAME and password is process.env.PASSWORD

app.use express.bodyParser()

unescaped = /[&<>]/

# Can't use underscore's escape because quotes are already escaped in Slack by
# default.
htmlEscapes =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'

reUnescapedHtml = RegExp "[#{(k for k of htmlEscapes).join ''}]", 'g'

escapeHtmlChar = (match) ->
  htmlEscapes[match]

escape = (string) ->
  return '' unless string?
  String(string).replace reUnescapedHtml, escapeHtmlChar

app.post '/', (req, res) ->
  payload = req.body

  if payload.action in ['opened', 'reopened']
    text = ":pray: #{payload.pull_request.user.login} #{payload.action} <#{payload.pull_request.html_url}|\"#{escape payload.pull_request.title}\"> on <#{payload.pull_request.base.repo.html_url}|#{escape payload.pull_request.base.repo.name}>. Take a look."
  else if payload.action is 'created'
    if /\b(?:lg(?:tm|btq?)|it seems great)\b/i.test payload.comment.body
      unless payload.comment.user.login is payload.issue.user.login # don't LGTM your own PR, ass
        text = ":+1: #{payload.comment.user.login} thinks that <#{payload.issue.html_url}|\"#{escape payload.issue.title}\"> is pretty rad!"
    else if /\bp[io]ng|synack\b/i.test payload.comment.body
      if payload.comment.user.login is payload.issue.user.login
        text = ":hand: #{payload.comment.user.login} has addressed comments on \"<#{payload.issue.html_url}|#{escape payload.issue.title}>\"."
      else
        text = ":golf: #{payload.comment.user.login} has left some comments on <#{payload.issue.html_url}|\"#{escape payload.issue.title}\">."

  return res.json 200 unless text?

  options =
    method: 'POST'
    uri: "https://#{process.env.SLACK_APP}.slack.com/services/hooks/incoming-webhook"
    qs:
      token: process.env.SLACK_TOKEN
    json:
      channel: process.env.SLACK_CHANNEL
      text: text
      username: 'github'
      icon_url: 'https://slack-assets2.s3-us-west-2.amazonaws.com/10562/img/services/github_48.png'

  request options, (err, response, body) ->
    if err
      res.json 500, err
    else
      res.json response.statusCode, body

port = Number process.env.PORT or 5000

app.listen port, ->
  console.log "Listening on #{port}"
