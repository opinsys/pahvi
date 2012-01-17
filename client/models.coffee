

models = NS "Example.models"


class LocalStore extends Backbone.Model

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



class models.Settings extends LocalStore
  defaults:
    mode: "edit"

class models.TextBoxModel extends LocalStore

  defaults:
    top: "100px"
    left: "100px"
    zIndex: 100
    text: "TextBox sample content"



