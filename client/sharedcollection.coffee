
log = (msg...) ->
  msg.unshift "SharedCollection:"
  console?.log.apply console, msg

S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)


class Backbone.SharedCollection extends Backbone.Collection

  @generateGUID = ->
    S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()

  constructor: (models, opts) ->
    @sharejsId = opts.sharejsId
    @modelTypes = opts.modelTypes
    super

  _initModel: (json) ->
    Model = @modelTypes[json.type]

    if not Model
      log "DEBUG: no custom model found for #{ json.type }"
      Model = Backbone.Model

    if not json.id
      log "DEBUG: User did not give an id. generating one"
      json.id Backbone.SharedCollection.generateGUID

    @add new Model json


  open: (cb=->) ->

    @_syncAttributes = {}

    sharejs.open @sharejsId, "json", (err, doc) =>
      return cb err if err
      @_syncDoc = doc

      if @_syncDoc.created
        log "DEBUG: Creating new collection #{ @sharejsId }"
        @_initSyncDoc()
      else
        log "DEBUG: opening existing collection #{ @sharejsId }"
        @_loadModelsFromSyncDoc()

      @_bindSendOperations()


      cb null, @_syncDoc.created

      # And also bind receive operations:
      @_syncDoc.on "remoteop", (operations) =>
        for op in operations
          # If first part in operation path is "models" this operation is a
          # change to some of the models
          if op.p[0] is "models"
            @_receiveModelOperation op
          else
            log "ERROR: Unknown Share js operation #{ JSON.stringify op }"


  _initSyncDoc: ->
    @_syncDoc.submitOp [
      p: []
      oi:
        models: {}
        collectionProperties: {}
    ]

  _loadModelsFromSyncDoc: ->
    for id, modelData of @_syncDoc.snapshot.models
      @_initModel modelData


  _bindSendOperations: ->

    @bind "change", (model) =>
      if model._syncOk
        @_sendModelChange model
      else
        log "Model #{ model.get "name" } is not in sync machinery yet. Skipping change event"

    @bind "add", (model) =>
      @_sendModelAdd model

    @bind "destroy", (model) =>
      @_sendModelDestroy model


  _sendModelChange: (model) ->

    operations = for attribute, value of model.changedAttributes()
      if @_syncAttributes[attribute] is value
        # We received this change. No need to resend it
        delete @_syncAttributes[attribute]
        continue

      log "SEND CHANGE: #{ model.get "name" }: #{ attribute }: #{ value }"
      { p: ["models", model.id, attribute ],  oi: value }


    if not @_syncDoc.snapshot.models[model.id]
      log "ERROR: snapshot has no this model"


    @_syncDoc.submitOp operations if operations.length isnt 0


  _sendModelAdd: (model) ->
    if @_syncAdded is model.id
      # We received this add. No need to resend it
      @_syncAdded = null
      return

    log "SEND ADD #{ model.get "name" }: #{ JSON.stringify model.toJSON() }"


    @_syncDoc.submitOp [
      p: ["models", model.id]
      oi: model.toJSON()
    ]


  _sendModelDestroy: (model) ->

    if @_syncRemoved is model.id
      # We received this remove. No need to send it again
      @_syncRemoved = null
      return

    log "SEND REMOVE #{ model.get "name" }"
    @_syncDoc.submitOp [
      p: ["models", model.id]
      od: true
    ]



  _receiveModelOperation: (op) ->

    # If path has form of [ "models", modelId ] it must be add or remove 
    if op.p.length is 2

      # We have insert object
      if op.oi
        return @_receiveModelAdd op

      # We have delete object
      if op.od
        return @_receiveModelDestroy op

    # If we have a third item in path it means that this is an attribute
    # update to existing model.
    if op.p[2]
      return @_receiveModelChange op


    log "Unkown model operation #{ JSON.stringify op }"


  _receiveModelAdd: (op) ->

    log "RECEIVE ADD #{ op.oi.name }: #{ JSON.stringify op.oi }"

    @_syncAdded = op.oi.id
    @_initModel op.oi


  _receiveModelDestroy: (op) ->
    modelId = op.p[1]

    model = @get modelId
    if not model
      log "ERROR: Remote asked to remove non existing model #{ modelId }"
      return

    log "RECEIVE REMOVE #{ model.get "name" }: #{ JSON.stringify modelId }"

    # Prevent resending this remove
    @_syncRemoved = model.id

    model.destroy()

    if @_syncDoc.snapshot.models[modelId]
      log "ERROR: Model exists after deletion! #{ modelId }"


  _receiveModelChange: (op) ->
    modelId = op.p[1]
    attrName = op.p[2]
    attrValue = op.oi


    model = @get modelId
    if not model
      log "ERROR: Remote asked to update non existing model: #{ model.get "name" } #{ modelId }"
      return

    log "RECEIVE CHANGE #{ model.get "name" }: #{ attrName }: #{ attrValue }"

    @_syncAttributes[attrName] = attrValue

    model.set @_syncAttributes


  add: (models) ->
    super

    if _.isArray models
      for m in models
        m._syncOk = true
    else
      models._syncOk = true

    return this


