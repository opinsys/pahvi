

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


log = (msg...) ->
  msg.unshift "ShareJS:"
  console.log.apply console, msg


class models.Boxes extends Backbone.Collection


  constructor: (models, opts) ->
    {@typeMapping} = opts
    {@id} = opts
    super

    @bind "sync", (box) =>
      @_syncToShareJs box.id, box.changedAttributes()

    @bind "add", (box) =>
      @_addNewBoxToShareJs box.toJSON()

    @bind "destroy", (box) =>
      @_removeBoxFromShareJs box.id


  open: (cb=->) ->
    sharejs.open @id, "json", (err, doc) =>
      return cb err if err
      @_syncDoc = doc


      if @_syncDoc.created
        console.log "NEW PAHVI"
        @_syncDoc.submitOp [
          p: []
          oi:
            boxes: {}
            cardboardProperties: {}
        ]
      else
        for id, boxData of @_syncDoc.snapshot.boxes
          @createBox boxData.type, boxData

      @_syncDoc.on "remoteop", (op) => @_onShareJsOperation op
      cb()


  _onShareJsOperation: (operations) ->
    console.log "GOT ShareJS op: #{ JSON.stringify operations }", @_syncDoc.snapshot
    for op in operations
      # Update to boxes
      if op.p[0] is "boxes"
        boxId = op.p[1]

        # Update to specific attribute
        if attr = op.p[2]
          @_syncFromShareJs boxId, attr
        else
          boxData = op.oi
          @createBox boxData.type, boxData

      else
        log "Unknown Share js operation #{ op.p[0] }"


  _syncFromShareJs: (boxId, attr) ->
    box = @get boxId

    if not box
      return log "Could not find box to update! #{ boxId }"

    log "Updating #{ attr } on #{ box.id }"
    box.syncSet @_syncDoc.snapshot.boxes[box.id]



  _syncToShareJs: (boxId, changedAttributes) ->
    console.log "CHANGED #{ boxId }: #{ JSON.stringify changedAttributes }"

    operations = for attribute, value of changedAttributes
      {
        p: ["boxes", boxId, attribute ]
        oi: value
      }

    @_syncDoc.submitOp operations


  _addNewBoxToShareJs: (attributes) ->
    console.log "ADD #{ JSON.stringify attributes }"
    @_syncDoc.submitOp [
      p: ["boxes", attributes.id]
      oi: attributes
    ]


  _removeBoxFromShareJs: (boxId) ->
    console.log "REMOVE #{ boxId }"


  comparator: (box) ->
    -1 * parseInt box.get "zIndex"

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  isUnique: (attr, value) ->
    not @find (box) -> box.get(attr) is value



  createBox: (type, options={}) ->
    if not options.id
      options.id = helpers.generateGUID()

    if @get options.id
      return log "Box id #{ options.id } already exists! Not creating new!"

    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    Model = @getModel type

    if not options?.name
      options.name = Model::defaults.name

    options.name = @makeUniqueName options.name

    @add new Model options


  makeUniqueName: (proposedName) ->


    name = proposedName
    i = 0

    while not @isUnique "name", name
      i += 1
      name = "#{ proposedName } #{ i }."

    return name




class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null


class BaseBoxModel extends Backbone.Model

  constructor: ->
    super
    @set type: @type

    # Convert change events to sync events
    @bind "change", =>
      # Skip sync if attribustes the attributes are exactly the same we just
      # set. This will prevent inifite update loops.
      if _.isEqual @changedAttributes(), @_syncedAttributes
        console.log "SYNC set skip for #{ @get "name" }"
        @_syncedAttributes = null
        return

      @trigger "sync", this

  syncSet: (attributes) ->
    @_syncedAttributes = attributes
    @set attributes

  destroy: (options) ->
    @trigger "destroy", this, this.collection, options


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


