
views = NS "Pahvi.views"


class views.ToolBox extends Backbone.View

  constructor: ->
    super
    @$el = $ @el
    source  = $("#toolboxTemplate").html()
    @template = Handlebars.compile source

  render: ->
    @$el.html @template()

class views.SideMenu extends Backbone.View


  constructor: ({@settings}) ->
    super
    @$el = $ @el

    source  = $("#sidemenuTemplate").html()
    @template = Handlebars.compile source

    @subviews =
      "toolbox": new views.ToolBox
      "layers": new views.Layers
        collection: @collection
        settings: @settings

    @settings.bind "change:sideMenu", =>
      console.log "Rendering subview"
      @renderSubview()

  events:
    "click a": "selectSubview"

  selectSubview: (e) ->
    e.preventDefault()
    @$("a").removeClass "active"
    $target = $(e.target).addClass "active"
    @settings.set sideMenu: $target.data("subview")

  renderSubview: ->

    currentView = @subviews[@settings.get("sideMenu") or "layers"]
    currentView.render()

    for k, view of @subviews
      view.$el.detach()

    @subviewContainer.html currentView.el

  render: ->
    @$el.html @template()
    @subviewContainer = @$(".media")
    @renderSubview()

