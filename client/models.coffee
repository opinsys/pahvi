

models = NS "Example.models"



class models.Boxes extends Backbone.Collection

  constructor: ->
    super

  comparator: (box) ->
    console.log "comparing"
    -1 * parseInt box.get "zIndex"


class LocalStore extends Backbone.Model

  constructor: ({name})->
    super

    @name = name

    if localStorage[@name]?
      @attributes = JSON.parse localStorage[@name]

    @bind "change", => @save()

  save: ->
    localStorage[@name] = JSON.stringify @attributes



class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null

class models.TextBoxModel extends LocalStore

  defaults:
    top: "100px"
    left: "100px"
    zIndex: 100
    text: "TextBox sample content"



