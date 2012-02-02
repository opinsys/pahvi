fs = require "fs"
{resize} = require "./resize"

express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server


rootDir = __dirname + "/../"
clientTmplDir = rootDir + "/views/client/"


defaults =
  port: 8080
  databaseType: "none"

try
  config = JSON.parse fs.readFileSync rootDir + "config.json"
catch e
  config = {}
  console.error "Could no load config.json. Using defaults."

for k, v of defaults
  config[k] ?= v


app = express.createServer()


css = piler.createCSSManager()
js = piler.createJSManager()



css.bind app
js.bind app
sharejs.attach app,
  db:
    type: config.databaseType


app.configure "development", ->
#  js.liveUpdate css


templateCache = {}
app.configure "production", ->
  console.log "Production mode detected!"
  for filename in fs.readdirSync clientTmplDir
    templateCache[filename] = fs.readFileSync(clientTmplDir + filename).toString()


app.configure ->
  app.use express.bodyParser()

  # Connect Handlebars to Piler Asset Manager
  hbs.registerHelper "renderScriptTags", (pile) ->
    js.renderTags pile
  hbs.registerHelper "renderStyleTags", (pile) ->
    css.renderTags pile

  # We want use same templating engine for the client and the server. We have
  # to workarount bit so that we can get uncompiled Handlebars templates
  # through Handlebars
  hbs.registerHelper "clientTemplate", (name) ->
    source = templateCache[name + ".hbs"]
    if not source
      # Synchronous file reading is bad, but it doesn't really matter here since
      # we can cache it in production
      source = fs.readFileSync rootDir + "/views/client/#{ name }.hbs"

    "<script type='text/x-template-handlebars' id='#{ name }Template' >#{ source }</script>\n"



  app.use express.static rootDir + '/public'
  app.set "views", rootDir + "/views"
  app.set 'view engine', 'hbs'



  js.addFile rootDir + "/client/vendor/jquery.js"
  js.addFile rootDir + "/client/vendor/handlebars.js"
  js.addFile rootDir + "/client/vendor/underscore.js"
  js.addFile rootDir + "/client/vendor/backbone.js"
  js.addFile rootDir + "/client/vendor/async.js"

  js.addFile rootDir + "/client/vendor/jquery-ui/jquery-ui.js"
  css.addFile rootDir + "/client/vendor/jquery-ui/jquery-ui.css"

  js.addFile rootDir + "/client/vendor/jquery.tools.min.js"

  js.addFile rootDir + "/client/vendor/jquery.transform.js"
  js.addFile rootDir + "/client/vendor/jquery.transformable-v.3.js"

  css.addFile rootDir + "/client/vendor/zoomooz/zoomooz.css"
  js.addFile rootDir + "/client/vendor/zoomooz/sylvester.js"
  js.addFile rootDir + "/client/vendor/zoomooz/purecssmatrix.js"
  js.addFile rootDir + "/client/vendor/zoomooz/jquery.animtrans.js"
  js.addFile rootDir + "/client/vendor/zoomooz/jquery.zoomooz.js"

  js.addFile rootDir + "/client/vendor/hallo/hallo.coffee"
  js.addFile rootDir + "/client/vendor/hallo/format.coffee"
  js.addFile rootDir + "/client/vendor/hallo/link.coffee"
  js.addUrl "/socket.io/socket.io.js"
  js.addUrl "/share/share.uncompressed.js"
  js.addUrl "/share/json.uncompressed.js"

  js.addFile rootDir + "/public/vendor/wymeditor/jquery.wymeditor.js"

  js.addFile rootDir + "/client/helpers.coffee"
  js.addFile rootDir + "/client/vendor/backbone.sharedcollection/src/backbone.sharedcollection.coffee"
  js.addFile rootDir + "/client/models.coffee"

  js.addFile rootDir + "/client/views/upload.coffee"
  js.addFile rootDir + "/client/views/box.coffee"
  js.addFile rootDir + "/client/views/layers.coffee"
  js.addFile rootDir + "/client/views/sidemenu.coffee"
  js.addFile rootDir + "/client/views/topmenu.coffee"
  js.addFile rootDir + "/client/views/lightbox.coffee"
  js.addFile rootDir + "/client/views/boxproperties.coffee"
  js.addFile rootDir + "/client/views/cardboard.coffee"

  js.addFile rootDir + "/client/main.coffee"

  css.addFile rootDir + "/client/styles/reset.styl"
  css.addFile rootDir + "/client/styles/main.styl"

  css.addFile "welcome", rootDir + "/client/styles/welcome.styl"
  js.addFile "welcome", rootDir + "/client/welcome.coffee"



types =
  "image/png": "png"
  "image/jpeg": "jpg"
  "image/jpg": "jpg"

app.post "/upload", (req, res, foo) ->

  if not ext = types[req.files.imagedata.type]
    res.json error: "Unkown file type"
    return

  fileId = "/tmp/01caf875dfbd0860ae3d9e6297d86182".split("/").reverse()[0]
  fileName = "#{ fileId }.#{ Date.now() }.#{ ext }"
  destination = rootDir + "public/userimages/#{ fileName }"

  resize req.files.imagedata.path, destination, 1200, (err) ->
    if err
      console.log "ERROR", err
      res.json error: "resize error"
    else
      res.json url: "/userimages/#{ fileName }"


app.get "/", (req, res) ->
  res.render "welcome"

app.get "/*", (req, res) ->
  res.render "index"


app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"
