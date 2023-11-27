<!DOCTYPE html>
<html lang="en">
  <head>
    <script src="/static/htmx.min.js"></script>
    <link rel="stylesheet" href="/static/app.css" />
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>
      <%= title or "Default title" -%>
    </title>
  </head>
  <body>
    <%- content -%>
  </body>
</html>
