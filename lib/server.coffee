fs = require "fs"


redis = require "redis"
express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server
nodemailer = require "nodemailer"
_  = require "underscore"
async = require "async"

{Validator} = require('validator')

check = do ->
  v = new Validator
  v.error = -> false
  -> v.check arguments...

RedisStore = require('connect-redis')(express)


{resize} = require "./resize"
{emailTemplate} = require "./emailtemplate"
{PahviMeta} = require "./pahvi"


sessionStore = new RedisStore

client = redis.createClient()

rootDir = __dirname + "/../"
clientTmplDir = rootDir + "/views/client/"

webutils = require("connect").utils

defaults =
  port: 8080
  sessionSecret: "Very secret string. (override me)"
  mailServer: "mail.opinsys.fi"
  googleAnalytics: "UA-9439432-4"

try
  config = JSON.parse fs.readFileSync rootDir + "config.json"
catch e
  config = {}
  console.error "Could no load config.json. Using defaults."

for k, v of defaults
  config[k] ?= v


nodemailer.SMTP =
  host: config.mailServer



app = express.createServer()


css = piler.createCSSManager()
js = piler.createJSManager()




prettifyAgent = (agent) ->
  "{ ip: #{ agent.remoteAddress }, id: #{ agent.id }: referer: #{ agent.headers?.referer } }"


css.bind app
js.bind app
sharejs.attach app,
  db:
    type: "redis"
  auth: (agent, action) ->

    if agent.editor
      action.accept()
      return

    if action.type isnt "update"
      action.accept()
      return

    # Aget does not give much information for us here. We need to manually
    # parse the cookie header and fetch the session from Redis
    cookies = webutils.parseCookie agent.headers.cookie

    sessionStore.get cookies["connect.sid"], (err, data) ->

      if err
        action.reject()
        console.log "ERROR: Could not read cookies from redis for #{ prettifyAgent agent }", err
        return

      if data.pahviAuth is "ok"
        action.accept()
        console.log "Auth ok for", prettifyAgent agent
        # Cache accept
        agent.editor = true
      else
        console.log "Unauthorized edit attempt from", prettifyAgent agent
        action.reject()


app.configure "development", ->
#  js.liveUpdate css


templateCache = {}
app.configure "production", ->
  console.log "Production mode detected!"
  for filename in fs.readdirSync clientTmplDir
    templateCache[filename] = fs.readFileSync(clientTmplDir + filename).toString()


hbs.registerHelper "googleAnalytics", ->
  """<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '#{ config.googleAnalytics }']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
"""



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

  js.addFile rootDir + "/client/vendor/noty/js/jquery.noty.js"
  css.addFile rootDir + "/client/vendor/noty/css/jquery.noty.css"

  js.addUrl "/socket.io/socket.io.js"

  # js.addUrl "/channel/bcsocket.js"
  js.addUrl "/share/share.uncompressed.js"
  js.addUrl "/share/json.uncompressed.js"

  js.addFile rootDir + "/public/vendor/wymeditor/jquery.wymeditor.js"

  js.addFile rootDir + "/client/helpers.coffee"
  js.addFile rootDir + "/client/vendor/backbone.sharedcollection/src/backbone.sharedcollection.coffee"
  js.addFile rootDir + "/client/models.coffee"

  js.addFile  rootDir + "/client/views/upload.coffee"
  js.addFile  rootDir + "/client/views/readonlylink.coffee"
  js.addFile  rootDir + "/client/views/box.coffee"
  js.addFile  rootDir + "/client/views/layers.coffee"
  js.addFile  rootDir + "/client/views/sidemenu.coffee"
  js.addFile  rootDir + "/client/views/topmenu.coffee"
  js.addFile  rootDir + "/client/views/lightbox.coffee"
  js.addFile  rootDir + "/client/views/boxproperties.coffee"
  js.addFile  rootDir + "/client/views/cardboard.coffee"
  js.addFile  rootDir + "/client/typemap.coffee"
  js.addFile  rootDir + "/client/connection.coffee"
  js.addFile  rootDir + "/client/router.coffee"

  js.addFile "pahvi", rootDir + "/client/main.coffee"

  js.addFile "remote", rootDir + "/client/remote.coffee"

  css.addFile rootDir + "/client/styles/reset.styl"
  css.addFile "pahvi", rootDir + "/client/styles/main.styl"
  css.addFile "remote", rootDir + "/client/styles/remote.styl"

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

  fileId = req.files.imagedata.path.split("/").reverse()[0]

  timestamp = Date.now()

  fileName = "box-image-#{ fileId }.#{ timestamp }.#{ ext }"
  destination = rootDir + "public/userimages/#{ fileName }"

  fileNameThumb = "box-image-#{ fileId }.#{ timestamp }.thumb.jpg"
  destinationThumb = rootDir + "public/userimages/#{ fileNameThumb }"

  async.parallel [
    (cb) -> resize req.files.imagedata.path, destination, 1200, cb
    (cb) -> resize req.files.imagedata.path, destinationThumb, 200, cb
  ], (err) ->
    if err
      console.log "ERROR resize", err
      res.json error: "resize error"
    else
      res.json url: "/userimages/#{ fileName }"


app.get "/", (req, res) ->
  res.render "welcome",
    layout: false
    config: config





app.post "/", (req, res) ->
  errors = []

  if req.body.email and not check(req.body.email).isEmail()
    errors.push
      message: "Bad email"
      field: "email"

  if not req.body.name?.trim()
    errors.push
      message: "Name is required"
      field: "name"

  if errors.length isnt 0
    return res.json
      error: errors

  pahvi = new PahviMeta
    client: client

  pahvi.create req.body, (err, result) ->
    throw err if err

    # TODO: This can fail in so many ways...
    result.publicUrl = "http://#{ req.headers.host }/p/#{ result.id }"
    result.adminUrl = "http://#{ req.headers.host }/e/#{ result.id }/#{ result.authKey }"

    res.json result

    if result.email
      sendMail result


sendMail = (ob, cb=->) ->

  if not config.mailServer
    console.error "Mail server not configured. Cannot send mail".
    return cb()

  {body, subject} = emailTemplate ob
  nodemailer.send_mail
    sender: 'dev@opinsys.fi',
    to: ob.email,
    subject: subject
    body: body
  , (err, success) ->
    cb err, success




app.get "/p/:id", (req, res, next) ->

  # XXX: Legacy auth url
  if req.query?.auth
    return res.redirect "/e/#{ req.params.id }/#{ req.query.auth }"

  req.session.pahviAuth = ""

  res.render "index",
    authKey: ""
    config: config
    data: {}



authRender = (template, layout="layout") -> (req, res, next) ->
  id = req.params.id

  pahvi = new PahviMeta
    client: client
    id: id

  response = ->
    pahvi.get (err, result) ->
      if err?.code is 404
        return res.redirect "/"
      res.render template,
        authKey: req.params.token
        config: config
        data: result
        layout: layout

  console.log "Authkey", req.params.token
  pahvi.authenticate req.params.token, (err, authOk) ->

    if authOk
      req.session.pahviAuth = "ok"
    else
      req.session.pahviAuth = ""

    response()

app.get "/e/:id/:token", authRender "index"
app.get "/r/:id/:token", authRender "remote", false





app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"
