

models = NS "Pahvi.models"



class models.Boxes extends Backbone.Collection

  constructor: ->
    super

  comparator: (box) ->
    console.log "comparing"
    -1 * parseInt box.get "zIndex"


class LocalStore extends Backbone.Model

  constructor: ->
    super

    if localStorage[@get("name")]?
      @attributes = JSON.parse localStorage[@get("name")]

    @bind "change", => @save()

  save: ->
    localStorage[@get("name")] = JSON.stringify @attributes

  destroy: ->
    delete localStorage[@get("name")]
    @trigger "destroy", this


class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null


class BaseBoxModel extends LocalStore

class models.TextBoxModel extends BaseBoxModel

  type: "text"

  defaults:
    name: "Text Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    text: "TextBox sample content"
    "backgroundColor": "white"



class models.PlainBoxModel extends BaseBoxModel

  type: "plain"

  defaults:
    name: "Plain Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    "backgroundColor": "white"

