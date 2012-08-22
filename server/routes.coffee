

_  = require "underscore"
async = require "async"
nodemailer = require "nodemailer"
{Validator} = require('validator')
redis = require "redis"

{resize} = require "./resize"
{emailTemplate} = require "./emailtemplate"
{PahviMeta} = require "./pahvi"

client = redis.createClient()

check = do ->
  v = new Validator
  v.error = -> false
  -> v.check arguments...

rootDir = __dirname + "/../"

types =
  "image/png": "png"
  "image/jpeg": "jpg"
  "image/jpg": "jpg"

module.exports = (app, js, css, config) ->

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
      css: css.renderTags "vendor", "welcome"
      js: js.renderTags "vendor", "loader"



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
      result.remoteUrl = "http://#{ req.headers.host }/r/#{ result.id }/#{ result.authKey }"

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
      js: js.renderTags "vendor", "loader"
      css: css.renderTags "vendor", "pahvi", "pahviui"



  authRender = (template, options={}) -> (req, res, next) ->
    id = req.params.id

    pahvi = new PahviMeta
      client: client
      id: id

    response = ->
      pahvi.get (err, result) ->
        if err?.code is 404
          return res.redirect "/"
        res.render template,
          _.extend
            authKey: req.params.token
            config: config
            data: result
            layout: true
          , options

    console.log "Authkey", req.params.token
    pahvi.authenticate req.params.token, (err, authOk) ->

      if authOk
        req.session.pahviAuth = "ok"
      else
        req.session.pahviAuth = ""

      response()

  app.get "/e/:id/:token", authRender "index",
    js: js.renderTags "vendor", "loader"
    css: css.renderTags "vendor", "pahvi", "pahviui"

  app.get "/r/:id/:token", authRender "remote",
    js: js.renderTags "vendor", "loader"
    css: css.renderTags "vendor", "pahvi", "remote"
    layout: false


