

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
      @_sendChange box

    @bind "add", (box) =>
      @_sendAdd box

    @bind "destroy", (box) =>
      @_sendRemove box


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

      cb()

      @_syncDoc.on "remoteop", (operations) =>
        for op in operations
          # If first part in operation path is "boxes" this operation is a
          # change to some of the boxes
          if op.p[0] is "boxes"
            @_receiveBoxOperation op
          else
            log "Unknown Share js operation #{ JSON.stringify op }"



  _sendChange: (box) ->
    changedAttributes = box.changedAttributes()

    log "Sending #{ box.id }: #{ JSON.stringify changedAttributes }"

    operations = for attribute, value of changedAttributes
      {
        p: ["boxes", box.id, attribute ]
        oi: value
      }

    @_syncDoc.submitOp operations


  _sendAdd: (box) ->
    console.log "Sending add #{ JSON.stringify box.toJSON() }"
    @_syncDoc.submitOp [
      p: ["boxes", box.id]
      oi: box.toJSON()
    ]


  _sendRemove: (box) ->
    console.log "Sending remove #{ box.id }"
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
        return @_receiveBoxRemove op

    # If we have a third item in path it means that this is an attribute
    # update to existing box.
    if op.p[2]
      return @_receiveBoxUpdate op


    log "Unkown box operation #{ JSON.stringify op }"


  _receiveBoxAdd: (op) ->
    log "Adding new box with attributes #{ op.oi }"
    @createBox op.oi.type, op.oi


  _receiveBoxRemove: (op) ->
    boxId = op.p[1]

    box = @get boxId
    if not box
      log "ERROR: Remote asked to remove non existing box #{ boxId }"
      return

    box.destroy()

    if @_syncDoc.snapshot.boxes[boxId]
      log "ERROR: Box exists after deletion! #{ boxId }"
    else
      log "DELETED box #{ boxId }"


  _receiveBoxUpdate: (op) ->
    boxId = op.p[1]
    box = @get boxId
    if not box
      log "ERROR: Remote asked to update non existing box #{ boxId }"
      return

    log "Remote update #{ op.p[2] }: #{ op.oi }"

    # Just update all attributes from sharejs snapshot
    box.syncSet @_syncDoc.snapshot.boxes[box.id]




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


