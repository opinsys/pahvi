
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

helpers = NS "Pahvi.helpers"


localStorage.debugSharedCollection = true

# Do not die if we have no logging function. Eg. FF without Firebug.
if not window.console?.log?
  window.console =
    log: ->


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
    text: msg + "<p><small>Please contact us at <a href=\"mailto:dev@opinsys.fi\">dev@opinsys.fi</a> if this issue persists.</small></p>"
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

S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)
helpers.generateGUID = ->
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()


helpers.roundNumber = (num, dec) ->
  Math.round(num*Math.pow(10,dec))/Math.pow(10,dec)
