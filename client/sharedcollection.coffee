
log = (msg...) ->
  msg.unshift "SharedCollection:"
  console?.log.apply console, msg

class Backbone.SharedCollection extends Backbone.Collection

  constructor: (models, opts) ->
    {@sharejsId} = opts
    super


  open: (cb=->) ->

    @_syncAttributes = {}

    sharejs.open @sharejsId, "json", (err, doc) =>
      return cb err if err
      @_syncDoc = doc

      if @_syncDoc.created
        @_initSyncDoc()
      else
        @_loadBoxesFromSyncDoc()

      @_bindSendOperations()


      cb null, @_syncDoc.created

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
      box = @createBox boxData.type, boxData


  _bindSendOperations: ->

    @bind "change", (box) =>
      if box._syncOk
        @_sendBoxChange box
      else
        log "Box #{ box.get "name" } is not in sync machinery yet. Skipping change event"

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

      log "SEND CHANGE: #{ box.get "name" }: #{ attribute }: #{ value }"
      { p: ["boxes", box.id, attribute ],  oi: value }


    if not @_syncDoc.snapshot.boxes[box.id]
      log "ERROR: snapshot has no this box"


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


  add: (models) ->
    super

    if _.isArray models
      for m in models
        m._syncOk = true
    else
      models._syncOk = true

    return this


