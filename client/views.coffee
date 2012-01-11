
views = NS "Example.views"

class views.Editor extends Backbone.View


  events:
    "keyup textarea": "update"

  constructor: ({name}) ->
    super
    @name = name

    source  = $("#editorTemplate").html()
    @template = Handlebars.compile source


  render: ->

    $(@el).html @template
      name: @name
      text: @model.get "text"

    @input = @$("textarea")


  update: ->
    console.log "editor: updating model"
    @model.set text: @input.val()



class views.Preview extends Backbone.View

  constructor: ->
    super

    @model.bind "change:text", =>
      @render()

  render: ->
    console.log "preview: reading model"
    $(@el).html @model.get "text"

