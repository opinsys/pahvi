

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
    @_syncAttributes = {}
    super



  open: (cb=->) ->


    sharejs.open @id, "json", (err, doc) =>
      return cb err if err
      @_syncDoc = doc

      if @_syncDoc.created
        @_initSyncDoc()
      else
        @_loadBoxesFromSyncDoc()

      @_bindSendOperations()


      cb()

      # And also bind receive operations:
      @_syncDoc.on "remoteop", (operations) =>
        for op in operations
          # If first part in operation path is "boxes" this operation is a
          # change to some of the boxes
          if op.p[0] is "boxes"
            @_receiveBoxOperation op
          else
            log "ERROR: Unknown Share js operation #{ JSON.stringify op }"


  _initSyncDoc: ->
    console.log "NEW PAHVI"
    @_syncDoc.submitOp [
      p: []
      oi:
        boxes: {}
        cardboardProperties: {}
    ]

  _loadBoxesFromSyncDoc: ->
    for id, boxData of @_syncDoc.snapshot.boxes
      @createBox boxData.type, boxData

  _bindSendOperations: ->

    @bind "change", (box) =>
      @_sendBoxChange box

    @bind "add", (box) =>
      @_sendBoxAdd box

    @bind "destroy", (box) =>
      @_sendBoxDestroy box


  _sendBoxChange: (box) ->

    operations = for attribute, value of box.changedAttributes()
      if @_syncAttributes[attribute] is value
        # We received this change. No need to resend it
        delete @_syncAttributes[attribute]
        continue

      log "SEND CHANGE: ", attribute, ":", value
      { p: ["boxes", box.id, attribute ],  oi: value }

    @_syncDoc.submitOp operations if operations.length isnt 0


  _sendBoxAdd: (box) ->
    if @_syncAdded is box.id
      # We received this add. No need to resend it
      @_syncAdded = null
      return

    log "SEND ADD #{ box.get "name" }: #{ JSON.stringify box.toJSON() }"

    @_syncDoc.submitOp [
      p: ["boxes", box.id]
      oi: box.toJSON()
    ]


  _sendBoxDestroy: (box) ->

    if @_syncRemoved is box.id
      # We received this remove. No need to send it again
      @_syncRemoved = null
      return

    log "SEND REMOVE #{ box.get "name" }"
    @_syncDoc.submitOp [
      p: ["boxes", box.id]
      od: true
    ]



  _receiveBoxOperation: (op) ->

    # If path has form of [ "boxes", boxId ] it must be add or remove 
    if op.p.length is 2

      # We have insert object
      if op.oi
        return @_receiveBoxAdd op

      # We have delete object
      if op.od
        return @_receiveBoxDestroy op

    # If we have a third item in path it means that this is an attribute
    # update to existing box.
    if op.p[2]
      return @_receiveBoxChange op


    log "Unkown box operation #{ JSON.stringify op }"


  _receiveBoxAdd: (op) ->

    log "RECEIVE ADD #{ op.oi.name }: #{ JSON.stringify op.oi }"

    @_syncAdded = op.oi.id
    @createBox op.oi.type, op.oi


  _receiveBoxDestroy: (op) ->
    boxId = op.p[1]

    box = @get boxId
    if not box
      log "ERROR: Remote asked to remove non existing box #{ boxId }"
      return

    log "RECEIVE REMOVE #{ box.get "name" }: #{ JSON.stringify boxId }"

    # Prevent resending this remove
    @_syncRemoved = box.id

    box.destroy()

    if @_syncDoc.snapshot.boxes[boxId]
      log "ERROR: Box exists after deletion! #{ boxId }"


  _receiveBoxChange: (op) ->
    boxId = op.p[1]
    attrName = op.p[2]
    attrValue = op.oi


    box = @get boxId
    if not box
      log "ERROR: Remote asked to update non existing box: #{ box.get "name" } #{ boxId }"
      return

    log "RECEIVE CHANGE #{ box.get "name" }: #{ attrName }: #{ attrValue }"

    @_syncAttributes[attrName] = attrValue

    box.set @_syncAttributes




  # Keep boxes sorted by they layer position
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
      return console.log  "ERROR: Box id #{ options.id } already exists! Not creating new!"

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


