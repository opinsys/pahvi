
views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

class views.Cardboard extends Backbone.View

  el: ".pahvi"


  # Create model/view/configure mapping of available Box types.  Box Models,
  # Views and Configure views are connected together by their `type` property.
  # This will go through those and creates `Cardboard.types` mapping for them.
  # Later this can be used to get corresponding View/Model/CongigureView
  Cardboard.types = {}
  for metaClassName, namespace of {Model: models, View: views, ConfView: configureViews}
    for __, metaClass of namespace when metaClass.prototype?.type
      Cardboard.types[metaClass.prototype.type] ?= {}
      Cardboard.types[metaClass.prototype.type][metaClassName] = metaClass



  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @collection.bind "add", (boxModel) =>

      {View} = Cardboard.types[boxModel.type]

      boxView = new View
        settings: settings
        model: boxModel

      @$el.append boxView.el

      boxView.render()
      boxView.activateDrag()

      @settings.set activeBox: boxModel.cid

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

    if not options?.name
      options.name = Model::defaults.name

    proposedName = options.name

    i = 0
    loop
      existing = @collection.find (m) ->
        m.get("name") is options.name

      break if not existing
      options.name = "#{ proposedName } #{ ++i }."

    boxModel = new Model name: options.name
    @collection.add boxModel
    boxModel

  render: ->
    @$el.droppable -> alert "drop"
