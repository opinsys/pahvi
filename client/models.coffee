

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

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  loadBoxes: (cb) ->
    for id, json_s of localStorage
      ob = JSON.parse json_s
      if ob.type
        Model = @getModel ob.type
        boxModel = new Model ob
        @add boxModel
    cb()

  makeUnique: (proposedId) ->
    i = 0
    id = proposedId

    while @get id
      i += 1
      id = "#{ proposedId } #{ i }."

    return id

  createBox: (type, options={}) ->
    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    {Model} = @typeMapping[type]

    if not options?.id
      options.id = Model::defaults.id

    options.id = @makeUnique options.id

    boxModel = new Model options
    @add boxModel


  save: ->


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


