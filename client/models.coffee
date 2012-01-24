

models = NS "Pahvi.models"
views = NS "Pahvi.views"


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


class LocalStore extends Backbone.Model

  constructor: ->
    super

    if localStorage[@get("id")]?
      @attributes = JSON.parse localStorage[@get("id")]

    @bind "change", => @save()

  save: ->
    localStorage[@get("id")] = JSON.stringify @attributes

  destroy: ->
    delete localStorage[@get("id")]
    @trigger "destroy", this


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
    "TextColor",
    "BackgroundColor",
    "FontSize",
    "Border"
  ]

  defaults:
    id: "Text Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    text: "<p>TextBox sample content</p>"
    "backgroundColor": "white"



class models.PlainBoxModel extends BaseBoxModel

  type: "plain"

  configs: [
    "BackgroundColor",
    "Border"
  ]

  defaults:
    id: "Plain Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    "backgroundColor": "white"


class models.ImageBox extends BaseBoxModel

  type: "image"

  configs: [
    "ImageSrc",
  ]

  defaults:
    id: "Image Box"
    top: "100px"
    left: "100px"
    zIndex: 100


