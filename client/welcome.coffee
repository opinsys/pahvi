

class Welcome extends Backbone.View


  constructor: ->
    super
    @$el = $ @el
  render: ->
    @$el.html @renderTemplate "welcomeform"



$ ->
  w = new Welcome
  w.render()
  w.$el.appendTo ".pahviForm"
