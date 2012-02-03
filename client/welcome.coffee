

class Welcome extends Backbone.View


  constructor: ->
    super
    @$el = $ @el

    @data = {}

  events:
    "click .submit": "_onClick"

  _onClick: ->
    @$(".spinner").css "visibility", "visible"

  _onSubmit: (response) ->

    if not response.error
      window.location = response.adminUrl
    else
      @data[response.field + "Error"] = response.error
      @render()


  render: ->
    @data.name = @$('[name="name"]').val()
    @data.email = @$('[name="email"]').val()
    @$el.html @renderTemplate "welcomeform", @data
    @$("form").ajaxForm => @_onSubmit arguments...



$ ->
  w = new Welcome
  w.render()
  w.$el.appendTo ".pahviForm"
