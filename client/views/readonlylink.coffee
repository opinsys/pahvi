
# Box that shows read only link in presentation mode.

views = NS "Pahvi.views"

class views.LinkBox extends Backbone.View

  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @settings.bind "change:mode", => @render()

  events:
    "click input": "selectLink"

  selectLink: (e) ->
    e.preventDefault()
    @$("input").get(0).select()


  render: ->

    if @settings.canEdit() and @settings.get("mode") is "presentation"
      @$el.html @renderTemplate "readonlylink",
        publicUrl: @settings.getPublicURL()
        adminUrl:  @settings.getAdminURL()
    else
      @$el.empty()
