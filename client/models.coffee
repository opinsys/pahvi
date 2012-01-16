

models = NS "Example.models"


class models.LocalStore extends Backbone.Model

  constructor: ({name})->
    super

    @name = name

    if localStorage[@name]?
      @attributes = JSON.parse localStorage[@name]

    @bind "change", =>
      console.log "store: saving model"
      @save()

  save: ->
    localStorage[@name] = JSON.stringify @attributes



class models.TextBoxModel extends models.LocalStore

  defaults:
    top: "100px"
    left: "100px"
    zIndex: 1000
    text: "TextBox sample content"



