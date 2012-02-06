fs = require "fs"


redis = require "redis"
express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server
nodemailer = require "nodemailer"
_  = require 'underscore'

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

    # Aget does not give much information for us here. We need to manually
    # parse the cookie header and fetch the session from Redis
    cookies = webutils.parseCookie agent.headers.cookie

    console.log "ShareJS: cookies", cookies

    sessionStore.get cookies["connect.sid"], (err, data) ->
      throw err if err
      console.log "ShareJS: Reading session:",  data
      if data.pahviAuth is "ok"
        action.accept()
        # Cache accept
        agent.editor = true
      else
        console.log "Unauthorized edit attempt"
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
    config: config





app.post "/", (req, res) ->

  if not check(req.body.email).isEmail()
    return res.json
      error: "Bad email"
      field: "email"

  if not req.body.name
    return res.json
      error: "Name is missing"
      field: "name"


  pahvi = new PahviMeta
    client: client

  pahvi.create req.body, (err, result) ->
    throw err if err

    # TODO: This can fail in so many ways...
    result.publicUrl = "http://#{ req.headers.host }/p/#{ result.id }"
    result.adminUrl = result.publicUrl + "?auth=#{ result.authKey }"

    res.json result
    sendMail result


sendMail = (ob, cb=->) ->
  {body, subject} = emailTemplate ob
  nodemailer.send_mail
    sender: 'dev@opinsys.fi',
    to: ob.email,
    subject: subject
    body: body
  , (err, success) ->
    console.log "MAIL", err, success
    cb err, success



app.get "/p/:id", (req, res, next) ->
  parts = req.path.split "/"
  if parts.length isnt 3
    return next()

  id = req.params.id

  pahvi = new PahviMeta
    client: client
    id: id

  response = ->
    pahvi.get (err, result) ->
      if err?.code is 404
        return res.redirect "/"
      res.render "index",
        authKey: req.query?.auth
        config: config

  if not req.query.auth
    req.session.pahviAuth = ""
    return response()


  pahvi.authenticate req.query?.auth, (err, authOk) ->

    console.log "Setting auth session: #{ authOk }"

    if authOk
      req.session.pahviAuth = "ok"
    else
      req.session.pahviAuth = ""

    response()





app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"
