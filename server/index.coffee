fs = require "fs"


express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server
nodemailer = require "nodemailer"
_  = require "underscore"


RedisStore = require('connect-redis')(express)



sessionStore = new RedisStore


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
  css.addFile rootDir + "/client/styles/generic.styl"
  css.addFile "pahvi", rootDir + "/client/styles/main.styl"
  css.addFile "remote", rootDir + "/client/styles/remote.styl"

  css.addFile "welcome", rootDir + "/client/styles/welcome.styl"
  js.addFile "welcome", rootDir + "/client/welcome.coffee"


# Add routes and real application logic
require("./routes") app, config

app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"