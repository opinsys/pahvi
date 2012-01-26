

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"



class models.Boxes extends Backbone.SharedCollection


  constructor: (models, opts) ->
    {@typeMapping} = opts
    super

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


