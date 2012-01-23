
views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

class views.Cardboard extends Backbone.View


  # Create model/view/configure mapping of available Box types.  Box Models,
  # Views and Configure views are connected together by their `type` property.
  # This will go through those and creates `Cardboard.types` mapping for them.
  # Later this can be used to get corresponding View/Model/CongigureView
  Cardboard.types = {}
  typeSources =
    Model: models
    View: views
  for metaClassName, namespace of typeSources
    for __, metaClass of namespace when metaClass.prototype?.type
      Cardboard.types[metaClass.prototype.type] ?= {}
      Cardboard.types[metaClass.prototype.type][metaClassName] = metaClass



  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @collection.bind "add", (boxModel) =>

      {View} = Cardboard.types[boxModel.type]

      boxView = new View
        settings: @settings
        model: boxModel

      @$el.append boxView.el

      boxView.render()
      boxView.activateDrag()

      @settings.set activeBox: boxModel.id

  events:
    "drop": "dropped"

  dropped: (e, ui) ->
    type = ui.draggable.data("boxtype")
    if type
      @createBox type,
        left: ui.offset.left + "px"
        top: ui.offset.top + "px"





  createBox: (type, options={}) ->
    if not Cardboard.types[type]
      return alert "Unkown type #{ type }!"

    {Model} = Cardboard.types[type]

    if not options?.id
      options.id = Model::defaults.id

    proposedId = options.id
    i = 0

    loop
      existing = @collection.find (m) ->
        m.id is options.id

      break if not existing
      options.id = "#{ proposedId } #{ ++i }."

    boxModel = new Model options
    @collection.add boxModel
    boxModel


  render: ->
    @$el.droppable()



