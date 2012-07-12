
# Namespace tool for accessing our namespace
#
# Usage:
#   bar = NS "PWB.foo.bar"
#
window.NS = (nsString) ->
  parent = window
  for ns in nsString.split "."
    # Create new namespace if it is missing
    parent = parent[ns] ?= {}
  parent # return the asked namespace

Pahvi = NS "Pahvi"
helpers = NS "Pahvi.helpers"

$.i18n.init
  fallbackLng: "en"
  sendMissing: true
  debug: true
  useLocalStorage: false
  dynamicLoad: true
  resGetPath: '/locales/resources.json?lng=__lng__&ns=__ns__'
  resPostPath: '/locales/add/__lng__/__ns__'

# Setup translation helpers
t = Pahvi.translate = $.i18n.t
Handlebars.registerHelper "t", (translationKey, opts) ->
  Pahvi.translate translationKey, opts
console.info "Language is #{ Pahvi.translate "lang" }"



localStorage.debugSharedCollection = true

# Do not die if we have no logging function. Eg. FF without Firebug.
["log", "info", "error"].forEach (method) ->
  if not window.console?[method]?
    window.console[method] = ->


templateCache = {}
helpers.template = (templateId, ob={}) ->
  if not templateFunction = templateCache[templateId]
    source = $("##{ templateId }Template").html()
    throw new Error "Unkown template #{ templateId }" if not source
    templateFunction = templateCache[templateId] = Handlebars.compile source
  return templateFunction ob

Backbone.View::renderTemplate = helpers.template



# Mobile detection
# Touch devices and devices with screens < 960 are mobile
# Borrowed from detectmobile.js
helpers.isMobile = do ->
  return true if "ontouchstart" of window
  length = Math.max window.screen.availWidth, window.screen.availHeight
  length <= 970



helpers.zoomOut = ->
  $("body").zoomTo
    targetSize: 1.0

helpers.loadImage = (url, cb=->) ->
  img = new Image
  img.onload = ->
    cb null, img
  img.src = url


helpers.showFatalError = (msg) ->
  noty
    text: msg + "<p><small>#{ t "main.contact" }</small></p>"
    layout: "center"
    type: "error"
    textAlign: "center"
    easing:"swing"
    animateOpen: {height:"toggle"}
    animateClose: {height:"toggle"}
    speed: "50"
    closable: false
    closeOnSelfClick: false
    modal: true
    timeout: false

helpers.showWarning = (msg) ->
  noty
    text: msg
    layout:"top"
    type:"error"
    textAlign:"center"
    easing:"swing"
    animateOpen:{height:"toggle"}
    animateClose:{height:"toggle"}
    speed:"500"
    timeout:false
    closable:true
    closeOnSelfClick:true

helpers.showNotification = (msg) ->
  noty
    text: msg
    layout:"bottom"
    type:"alert"
    textAlign:"center"
    easing:"swing"
    animateOpen:{height:"toggle"}
    animateClose:{height:"toggle"}
    speed:"500"
    timeout: 10000
    closable:true
    closeOnSelfClick:true

S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)
helpers.generateGUID = ->
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()


helpers.roundNumber = (num, dec) ->
  Math.round(num*Math.pow(10,dec))/Math.pow(10,dec)



downscale = (width, height, maxWidth) ->
  if width < maxWidth and height < maxWidth
    height = height
    width = width
  else if width > height
    scale = maxWidth / width
    width = maxWidth
    height = height * scale
  else
    scale = maxWidth / height
    height = maxWidth
    width = width * scale

  [width, height]

jQuery.fn.forceImageSize = (max, cb) ->
  @each ->
    img = new Image
    # Make sure that image is loaded. We cannot otherwise read its width and
    # height
    img.onload = =>
      [width, height] = downscale img.width, img.height, max
      console.log "Setting", width, height, @src
      @width = width
      @height = height
      cb?()
    img.src = @src




