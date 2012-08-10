fs = require "fs"


express = require "express"
hbs = require "hbs"
piler = require "piler"
sharejs = require("share").server
nodemailer = require "nodemailer"
_  = require "underscore"
i18next = require "i18next"
path = require "path"



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


DEVELOP = true
templateCache = {}
app.configure "production", ->
  DEVELOP = false
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

hbs.registerHelper "appsources", ->
  data =
    app: (s[0] for s in js.getSources "pahvi", "pahviui")
    welcome: (s[0] for s in js.getSources "pahvi", "welcome")
    remote: (s[0] for s in js.getSources "pahvi", "remote")
  return """
  <script type="text/javascript">
  window.PahviSources = #{ JSON.stringify data };
  </script>
  """


app.configure ->
  app.use express.bodyParser()
  app.use i18next.handle
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

  css.addFile "vendor", rootDir + "/client/styles/reset.styl"

  js.addFile "vendor", rootDir + "/client/vendor/jquery.js"

  js.addFile "vendor", rootDir + "/client/vendor/i18next.js"

  js.addFile "vendor", rootDir + "/client/vendor/handlebars.js"
  js.addFile "vendor", rootDir + "/client/vendor/underscore.js"
  js.addFile "vendor", rootDir + "/client/vendor/backbone.js"

  js.addFile "vendor", rootDir + "/client/vendor/async.js"
  js.addFile "vendor", rootDir + "/client/vendor/parseuri.js"

  js.addFile "vendor", rootDir + "/client/vendor/jquery.form.js"

  js.addFile "vendor", rootDir + "/client/vendor/noty/js/jquery.noty.js"
  css.addFile "vendor", rootDir + "/client/vendor/noty/css/jquery.noty.css"

  js.addFile "vendor", rootDir + "/client/vendor/tipsy/src/javascripts/jquery.tipsy.js"
  css.addFile "vendor", rootDir + "/client/vendor/tipsy/src/stylesheets/tipsy.css"
  js.addFile "vendor", rootDir + "/client/helpers.coffee"

  js.addUrl "pahvi", "/socket.io/socket.io.js"
  # js.addUrl "/channel/bcsocket.js"
  js.addUrl "pahvi", "/share/share.uncompressed.js"
  js.addUrl "pahvi", "/share/json.uncompressed.js"



  js.addFile "pahvi", rootDir + "/client/vendor/jquery-ui/jquery-ui.js"
  css.addFile "pahvi", rootDir + "/client/vendor/jquery-ui/jquery-ui.css"

  js.addFile "pahviui", rootDir + "/client/vendor/jquery.transform.js"
  js.addFile "pahviui", rootDir + "/client/vendor/jquery.transformable-v.3.js"

  js.addFile "pahvi", rootDir + "/client/vendor/jquery.zoomooz.js"



  js.addFile "pahviui", rootDir + "/client/vendor/colorjoe/dist/colorjoe.js"
  css.addFile "pahviui", rootDir + "/client/vendor/colorjoe/css/colorjoe.css"



  js.addFile "pahviui", rootDir + "/public/vendor/wymeditor/jquery.wymeditor.js"

  js.addFile "pahvi", rootDir + "/client/vendor/backbone.sharedcollection/src/backbone.sharedcollection.coffee"
  js.addFile "pahvi", rootDir + "/client/models.coffee"
  js.addFile  "pahvi", rootDir + "/client/connection.coffee"

  js.addFile  "pahviui", rootDir + "/client/views/upload.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/readonlylink.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/box.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/layers.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/sidemenu.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/topmenu.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/lightbox.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/boxproperties.coffee"
  js.addFile  "pahviui", rootDir + "/client/views/cardboard.coffee"
  js.addFile  "pahviui", rootDir + "/client/typemap.coffee"
  js.addFile  "pahviui", rootDir + "/client/router.coffee"
  js.addFile "pahviui", rootDir + "/client/main.coffee"
  css.addFile "pahviui", rootDir + "/client/styles/generic.styl"
  css.addFile "pahviui", rootDir + "/client/styles/main.styl"


  js.addFile "remote", rootDir + "/client/vendor/handlebars.js"
  js.addFile "remote", rootDir + "/client/remote.coffee"

  css.addFile "remote", rootDir + "/client/styles/remote_generic.styl"
  css.addFile "remote", rootDir + "/client/styles/remote.styl"


  css.addFile "welcome", rootDir + "/client/styles/welcome.styl"
  js.addFile "welcome", rootDir + "/client/welcome.coffee"


  js.addFile "loader", rootDir + "/client/vendor/head.js"
  js.addFile "loader", rootDir + "/client/load.coffee"


  resPath = path.normalize "#{ rootDir }/locales/__lng__/__ns__.json"

  i18next.init
    fallbackLng: 'en'
    sendMissingTo: "all"
    sendMissing: true
    resGetPath: resPath
    resSetPath: resPath
    debug: DEVELOP

  i18next.serveClientScript(app)
         .serveDynamicResources(app)
         .serveMissingKeyRoute(app)
         .serveChangeKeyRoute(app)

  hbs.registerHelper "t", (translationKey, opts) ->
    (new hbs.SafeString i18next.t translationKey, opts) + "*"

# Add routes and real application logic
require("./routes") app, js, css, config

app.listen config.port, ->
  console.log "Now listening on port #{ config.port }"
