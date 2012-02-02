

class Welcome extends Backbone.View


  constructor: ->
    super
    @$el = $ @el


  _onSubmit: (response) ->

    if not response.error
      return window.location = "/#{ response.id }?auth=#{ response.authKey }"

    alert "error: #{ response.error }"




  render: ->
    @$el.html @renderTemplate "welcomeform"
    @$("form").ajaxForm => @_onSubmit arguments...



$ ->
  w = new Welcome
  w.render()
  w.$el.appendTo ".pahviForm"
