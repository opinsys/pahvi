
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


helpers.zoomOut = ->
  $("body").zoomTo
    targetSize: 1.0

helpers.preloadImage = (url, cb=->) ->
  img = new Image
  img.onload = -> cb()
  img.src = url

S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)
helpers.generateGUID = ->
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()

