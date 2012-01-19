

views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

class Cardboard extends Backbone.View

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
      boxView.startDrag()

  events:
    "drop": "dropped"

  dropped: (event, ui) ->
    type = ui.draggable.data("boxtype")
    @createBox type if type





  createBox: (type, name) ->
    if not Cardboard.types[type]
      return alert "Unkown type #{ type }!"

    {Model} = Cardboard.types[type]

    name or= Model::defaults.name

    proposedName = name
    i = 0
    loop
      existing = @collection.find (m) ->
        m.get("name") is name

      break if not existing
      name = "#{ proposedName } #{ ++i }."

    boxModel = new Model name: name
    @collection.add boxModel
    boxModel

  render: ->
    @$el.droppable -> alert "drop"

$ ->

  window.settings = new models.Settings
    name: "settings"


  menu = new views.Menu
    el: ".menu"
    settings: settings
  menu.render()

  boxes = new models.Boxes
  boxes.bind "add", -> console.log "box added"

  window.sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()


  parent = $(".pahvi")

  addTextBox = (name) ->
    m = new models.TextBoxModel
      name: name

    boxes.add m

    t = new views.TextBox
      settings: settings
      model: m

    parent.append t.el

    t.render()
    t.startDrag()


  addTextBox "a"
  addTextBox "b"
  addTextBox "c"
  addTextBox "d"

