<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="/favicon.png">
  <title>Cognito demo</title>
</head>
<body>
  <h1>Cognito basic demo</h1>
  <p><a href="https://${domain}.auth.${region}.amazoncognito.com/oauth2/authorize?response_type=token&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=openid%20email%20profile">Login with Cognito</a></p>
</body>
</html>
