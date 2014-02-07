Setup:
* Create a Heroku app.
* Fill out the ``USERNAME``, ``PASSWORD``, ``SLACK_APP``,
  ``SLACK_CHANNEL``, and ``SLACK_TOKEN`` configuration variables using
  ``heroku config:set``.
* Push this app to Heroku.
* Set up GitHub hooks for your repos: ``curl -H 'Authorization: token <GITHUB_TOKEN>' --data '{"name":"web","active":true,"events":["pull_request","issue_comment"],"config":{"url":"https://<USERNAME>:<PASSWORD>@<HEROKU_URL>/","insecure_ssl":false,"content_type":"json"}}' https://api.github.com/repos/<GITHUB_USERNAME>/<GITHUB_REPO>/hooks``
