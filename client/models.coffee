

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


class models.Boxes extends Backbone.Collection

  constructor: (models, opts) ->
    {@typeMapping} = opts
    {@id} = opts
    super


  comparator: (box) ->
    -1 * parseInt box.get "zIndex"

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  isUnique: (attr, value) ->
    not @find (box) -> box.get(attr) is value

  loadBoxes: (sharejsdoc, totalCb) ->
    console.log @id
    sharejsdoc.open @id, 'json', (err, doc) =>
      throw err if err
      @sharejsdoc = doc
      @sharejsdoc.on 'remoteop', (op) =>
        console.log "event: remoteop, model change"
        console.log op
        # Search model
        model_id = op[0]["p"][0]
        if model = @get model_id
          console.log model
          console.log op
          newAttributes = {}
          for one in op
            key = one["p"][1]
            value = one["oi"]
            newAttributes[key] = value
          model.update newAttributes
        else
          modelId = op[0]["p"][0]
          modelAttributes = op[0]["oi"]
          Model = @getModel modelAttributes["type"]

          @openBox new Model modelAttributes

      if @sharejsdoc.snapshot == null
        @sharejsdoc.submitOp([{p:[], od:null, oi:{}}])

      if @sharejsdoc.snapshot != ""
        boxMetaData = for k, value of @sharejsdoc.snapshot
          value
        console.log @sharejsdoc.snapshot
        console.log "BoxMetaData"
        console.log boxMetaData

        async.forEach boxMetaData, (ob, cb) =>

          Model = @getModel ob.type

          boxModel = new Model(ob)

          @openBox boxModel, cb

        , totalCb
      else
        totalCb


  createBox: (type, options={}) ->
    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    Model = @getModel type

    if not options?.name
      options.name = Model::defaults.name

    options.name = @makeUniqueName options.name

    options.id = helpers.generateGUID()

    proposedId = options.id
    i = 0

    loop
      existing = @find (m) ->
        m.id is options.id

      break if not existing
      options.id = "#{ proposedId } #{ ++i }."

    @openBox new Model options

  openBox: (box, cb=->) ->
    box.dirty = true
    box.open @sharejsdoc, (err) =>
      throw err if err
      @add box
      cb()

  makeUniqueName: (proposedName) ->


    name = proposedName
    i = 0

    while not @isUnique "name", name
      i += 1
      name = "#{ proposedName } #{ i }."

    return name


class LocalStore extends Backbone.Model

  constructor: ->
    super

  destroy: ->
    @doc.submitOp([{ p:[@id], od:null}])
    @trigger "destroy", this

  update: (changedAttributes) ->
    console.log "method: update. set attributes to model"
    @alreadySaved = changedAttributes
    @set changedAttributes

  send: (attributes) ->
    console.log "method: send"
    if @doc.snapshot[@id]?
      console.log "Send model attributes to another browser"
      submitOpValue = []
      for key, value of attributes
        submitOpValue.push { p:[@id,key], od:null, oi:value }
      @doc.submitOp(submitOpValue)
    else
      console.log "Send new model to another browser"
      @doc.submitOp([{ p:[@id], oi:attributes }])
    console.log @doc.snapshot


  open: (sharejsdoc, cb) ->
    @bind "change", =>
      console.log "One Box change, open"
      if not _.isEqual @changedAttributes(), @alreadySaved
        console.log "not already saved -> send to sharejs"
        # FIXME send only changed attributes
        if @dirty
          @send @toJSON()
          @dirty = false
        else
          @send @changedAttributes()
        @alreadySaved = null
      else
        console.log "Attributes has already saved!"

    @doc = sharejsdoc
    cb()


class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null


class BaseBoxModel extends LocalStore

  constructor: ->
    super
    @set type: @type



class models.TextBoxModel extends BaseBoxModel

  type: "text"

  configs: [
    "NameEditor",
    "TextColor",
    "BackgroundColor",
    "FontSize",
    "Border"
  ]

  defaults:
    name: "Text Box"
    top: "100px"
    left: "100px"
    width: "200px"
    height: "200px"
    zIndex: 100
    text: "<p>TextBox sample content</p>"
    "backgroundColor": "white"



class models.PlainBoxModel extends BaseBoxModel

  type: "plain"

  configs: [
    "NameEditor",
    "BackgroundColor",
    "Border"
  ]

  defaults:
    name: "Plain Box"
    top: "100px"
    left: "100px"
    width: "200px"
    height: "200px"
    zIndex: 100
    "backgroundColor": "white"


class models.ImageBox extends BaseBoxModel

  type: "image"

  configs: [
    "NameEditor",
    "ImageSrc",
  ]

  defaults:
    name: "Image Box"
    top: "100px"
    left: "100px"
    width: "200px"
    height: "200px"
    zIndex: 100


