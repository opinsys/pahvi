express = require "express"
hbs = require "hbs"
piler = require "piler"


app = express.createServer()


css = piler.createCSSManager()
js = piler.createJSManager()



css.bind app
js.bind app


app.configure ->
  # Connect Piler and Handlebars
  hbs.registerHelper "renderScriptTags", (pile) ->
    js.renderTags pile
  hbs.registerHelper "renderStyleTags", (pile) ->
    css.renderTags pile

  app.set "views", __dirname + "/views"
  app.set 'view engine', 'hbs'


  js.addFile __dirname + "/client/vendor/jquery.js"
  js.addFile __dirname + "/client/vendor/handlebars.js"
  js.addFile __dirname + "/client/vendor/underscore.js"
  js.addFile __dirname + "/client/vendor/backbone.js"

  js.addFile __dirname + "/client/helpers.coffee"
  js.addFile __dirname + "/client/application.coffee"
  css.addFile __dirname + "/client/style.styl"

app.configure "development", ->
  js.liveUpdate css, io



app.get "/", (req, res) ->
  res.render "index"


app.bind 8080, ->
  console.log "Now listening on port 8080"
