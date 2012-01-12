fs = require "fs"

express = require "express"
hbs = require "hbs"
piler = require "piler"

rootDir = __dirname + "/../"

app = express.createServer()


css = piler.createCSSManager()
js = piler.createJSManager()



css.bind app
js.bind app



app.configure ->

  # Connect Handlebars to Piler Asset Manager
  hbs.registerHelper "renderScriptTags", (pile) ->
    js.renderTags pile
  hbs.registerHelper "renderStyleTags", (pile) ->
    css.renderTags pile

  # We want use same templating engine for the client and the server. We have
  # to workarount bit so that we can get uncompiled Handlebars templates
  # through Handlebars
  templateCache = {}
  hbs.registerHelper "clientTemplate", (name) ->
    source = templateCache[name]
    if not source
      # Synchronous file reading is bad, but it doesn't really matter here since
      # we can cache it in production
      source = fs.readFileSync rootDir + "/views/client/#{ name }.hbs"
      templateCache[name] = source if process.env["NODE_ENV"] is "production"

    "<script type='text/x-template-handlebars' id='#{ name }Template' >#{ source }</script>\n"



  app.set "views", rootDir + "/views"
  app.set 'view engine', 'hbs'


  js.addFile rootDir + "/client/vendor/jquery.js"
  js.addFile rootDir + "/client/vendor/handlebars.js"
  js.addFile rootDir + "/client/vendor/underscore.js"
  js.addFile rootDir + "/client/vendor/backbone.js"
  js.addFile rootDir + "/client/vendor/async.js"

  js.addFile rootDir + "/client/helpers.coffee"
  js.addFile rootDir + "/client/models.coffee"
  js.addFile rootDir + "/client/views.coffee"
  js.addFile rootDir + "/client/main.coffee"

  css.addFile rootDir + "/client/styles/reset.styl"
  css.addFile rootDir + "/client/styles/main.styl"


app.configure "development", ->
  js.liveUpdate css

app.configure "production", ->
  console.log "Production mode detected!"


app.get "/", (req, res) ->
  res.render "index"


app.listen 8080, ->
  console.log "Now listening on port 8080"
