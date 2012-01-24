

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


class models.Boxes extends Backbone.Collection

  constructor: (opts) ->
    {@typeMapping} = opts
    {@id} = opts
    delete opts.typeMapping
    delete opts.id
    super

    @bind "add", => @save()


  comparator: (box) ->
    -1 * parseInt box.get "zIndex"

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  isUnique: (attr, value) ->
    not @find (box) -> box.get(attr) is value

  loadBoxes: (totalCb) ->

    @sharejsdoc.open (err) ->
      throw err if err

      boxMetaData = for k, value of @sharejsdoc.snapshot[@id]
        # XXX
        { id: value.id, type: value.type }

      async.forEach boxMetaData, (ob, cb) ->

        Model = @getModel ob.type

        boxModel = new Model
          id: ob.id

        @openBox.openBox boxModel, cb

      , totalCb


  createBox: (type, options={}) ->
    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    Model = @getModel type

    if not options?.id
      options.id = Model::defaults.id

    proposedId = options.id
    i = 0

    loop
      existing = @find (m) ->
        m.id is options.id

      break if not existing
      options.id = "#{ proposedId } #{ ++i }."

    @openBox new Model options

  openBox: (box, cb=->) ->
    box.open @sharejsdoc, (err) ->
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
    console.log "Not implemented"

  update: (changedAttributes) ->
    console.log "method: update. set attributes to model"
    @alreadySaved = changedAttributes
    @set changedAttributes


  open: (cb) ->
    @bind "change", =>
      console.log "method: open, model change"
      if not _.isEqual @changedAttributes(), @alreadySaved
        console.log "not already saved -> send to sharejs"
        @send @changedAttributes()
        @aleardySave = null
      else
        console.log "Attributes has already saved!"


    sharejs.open @get('id'), 'json', (err, doc) =>
      console.log "Open new doc: " + @get('id')
      @doc = doc
      if @doc.snapshot == null
        @doc.submitOp([{p:[], od:null, oi:{}}])
      else
        console.log "Set/update attributes from sharejs"
        @update @doc.snapshot

      @doc.on 'remoteop', (op) =>
        console.log "event: remoteop, model change: " + @get('id')
        if op[0]["p"].length == 0
          console.log "update all attributes"
          @update @doc.snapshot
        else
          new_attributes = {}
          for o in op
            attr = o["p"][0]
            new_attributes[o["p"][0]] = @doc.snapshot[attr]
          console.log "update special attributes"
          @update new_attributes
      cb err

  send: (attributes) ->
    console.log "method: send"
    submitOpValue = []
    for key, value of attributes
      submitOpValue.push { p:[key], od:null, oi:value }
    @doc.submitOp(submitOpValue)


  open: (sharejsdoc, cb) ->
    @doc = sharejsdoc
    @set sharejsdoc.snapshot[@id] # XXX ....
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
    zIndex: 100


