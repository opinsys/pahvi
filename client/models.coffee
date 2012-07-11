

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"



class models.Boxes extends Backbone.SharedCollection


  constructor: (models, opts) ->
    {@typeMapping} = opts
    super

    @bind "change:zIndex", (box) => @sort()


  # Keep boxes sorted by they layer position
  comparator: (box) ->
    -1 * parseInt box.get "zIndex"

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  isUnique: (attr, value) ->
    not @find (box) -> box.get(attr) is value

  updateZIndexes: (orderedIds) ->

    @disableSort = true

    for id, index in orderedIds
      if model = @get id
        model.set zIndex: index + 100

    @disableSort = false

    @sort()


  sort: ->
    if not @disableSort
      super


  createBox: (type, options={}) ->

    if @get options.id
      return console.log  "ERROR: Box id #{ options.id } already exists! Not creating new!"

    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    Model = @getModel type

    if not options?.name
      options.name = Model::defaults.name

    options.name = @makeUniqueName options.name

    if @size() isnt 0
      options.zIndex = @max( (box) -> box.get("zIndex") ).get("zIndex") + 1

    @add box = new Model options
    return box


  makeUniqueName: (proposedName) ->


    name = proposedName
    i = 0

    while not @isUnique "name", name
      i += 1
      name = "#{ proposedName } #{ i }."

    return name


  getOrCreate: (id, Model=Backbone.Model) ->

    if model = @get id
      return model

    model = new Model id: id
    @add model
    return model




class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null

  constructor: ->
    @pahviId = window.location.pathname.split("/")[2]
    @_uri = parseUri window.location.href
    super

  getPublicURL: ->
    "#{ @_uri.protocol }://#{ @_uri.authority }/p/#{ @pahviId }"

  getAdminURL: ->
    "#{ @_uri.protocol }://#{ @_uri.authority }/e/#{ @pahviId }/#{ window.AUTH_KEY }"

  getRemoteURL: ->
    "#{ @_uri.protocol }://#{ @_uri.authority }/r/#{ @pahviId }/#{ window.AUTH_KEY }"

  getAuthKey: ->
    window.AUTH_KEY

  canEdit: ->
    !! window.AUTH_KEY


class BaseBoxModel extends Backbone.Model

  getPreviewHtml: -> ""

  # Getter extension http://stackoverflow.com/a/6696112/153718
  get: (attr) ->
    if typeof(getter = this["_bbGet_" + attr]) is "function"
      return getter.call this, attr
    super

  # If visibility is undefined default to visible
  _bbGet_visible: (attr) ->
    val = @attributes[attr]
    if typeof(val) is "undefined"
      return true
    return val

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


  getPreviewHtml: ->
    $("<div>").html(@get "text").text().substring(0, 100)

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
    imgSrc: "/img/noimage.png"

  hasThumbnail: -> !! @get("imgSrc").match(/\/userimages\/box\-image\-/)

  getThumbnailUrl: -> @get("imgSrc").replace(/\.\w+$/, ".thumb.jpg")

  getPreviewHtml: ->
    console.log "IMAGE", @get("imgSrc")
    if @hasThumbnail()
      """
      <img src="#{ @getThumbnailUrl() }" class=imageBoxThumbnail />
      """
    else
      ""




