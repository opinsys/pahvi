fs = require "fs"


redis = require "redis"
express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server

RedisStore = require('connect-redis')(express)

sessionStore = new RedisStore

urlshortener = require "./urlshortener"
{resize} = require "./resize"
{PahviMeta} = require "./pahvi.coffee"


client = redis.createClient()

rootDir = __dirname + "/../"
clientTmplDir = rootDir + "/views/client/"

webutils = require("connect").utils

defaults =
  port: 8080
  sessionSecret: "change me"

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
    type: "redis"
  auth: (agent, action) ->

    if agent.editor
      console.log "Agent is editor. (cache)"
      action.accept()
      return


    if action.type isnt "update"
      action.accept()
      return

    cookies = webutils.parseCookie agent.headers.cookie
    console.log "ShareJS: cookies", cookies
    sessionStore.get cookies["connect.sid"], (err, data) ->
      throw err if err
      console.log "ShareJS: Reading session:",  data
      if data.pahviAuth is "ok"
        action.accept()
        agent.editor = true
      else
        console.error "Unauthorized edit attempt"
        action.reject()


app.configure "development", ->
#  js.liveUpdate css


templateCache = {}
app.configure "production", ->
  console.log "Production mode detected!"
  for filename in fs.readdirSync clientTmplDir
    templateCache[filename] = fs.readFileSync(clientTmplDir + filename).toString()



app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session
    secret: config.sessionSecret
    store: sessionStore

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
  js.addFile rootDir + "/client/vendor/parseuri.js"

  js.addFile rootDir + "/client/vendor/jquery.form.js"

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

  js.addFile "pahvi", rootDir + "/client/main.coffee"

  css.addFile rootDir + "/client/styles/reset.styl"
  css.addFile "pahvi", rootDir + "/client/styles/main.styl"

  css.addFile "welcome", rootDir + "/client/styles/welcome.styl"
  js.addFile "welcome", rootDir + "/client/welcome.coffee"



types =
  "image/png": "png"
  "image/jpeg": "jpg"
  "image/jpg": "jpg"

app.post "/upload", (req, res) ->

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
  res.render "welcome",
    layout: false


S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)

createPahvi = (options, cb) ->







app.post "/", (req, res) ->
  pahvi = new PahviMeta
    client: client

  pahvi.create req.body, (err, result) ->
    throw err if err
    res.json result



app.get "/*", (req, res, next) ->
  parts = req.path.split "/"
  if parts.length isnt 2
    return next()

  [__, id] = parts

  pahvi = new PahviMeta
    client: client

  response = ->
    pahvi.get id, (err, result) ->
      if err?.code is 404
        return res.redirect "/"
      res.render "index",
        authKey: req.query?.auth

  if not req.query.auth
    return response()


  pahvi.authenticate id, req.query?.auth, (err, authOk) ->

    console.log "Setting auth session: #{ authOk }"

    if authOk
      req.session.pahviAuth = "ok"
    else
      req.session.pahviAuth = ""

    response()





app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"
