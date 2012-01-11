

models = NS "Example.models"


class models.Store extends Backbone.Model

  constructor: ({name})->
    super

    @name = name

    if localStorage[@name]?
      @attributes = JSON.parse localStorage[@name]

    @bind "change", =>
      console.log "store: saving model"
      localStorage[@name] = JSON.stringify @toJSON()

