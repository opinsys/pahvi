


Pahvi = NS "Pahvi"

Pahvi.translate = ->
  throw new Error "Translations are not loaded yet!"
  "Translations are not loaded yet!"

routes =
  "/": PahviSources.welcome
  "/e": PahviSources.app
  "/p": PahviSources.app
  "/r": PahviSources.remote

$.i18n.init
  fallbackLng: "en"
  sendMissing: true
  debug: true
  useLocalStorage: false
  dynamicLoad: true
  resGetPath: '/locales/resources.json?lng=__lng__&ns=__ns__'
  resPostPath: '/locales/add/__lng__/__ns__'
, (t) ->

  Pahvi.translate = t
  path = parseUri(window.location.href).path

  sources = (
    "/": PahviSources.welcome
    "/e": PahviSources.app
    "/p": PahviSources.app
    "/r": PahviSources.remote
  )[path.match(/^\/[epr]?/) or "/"]
  head.js sources..., ->
    console.info "Sources loaded!"
