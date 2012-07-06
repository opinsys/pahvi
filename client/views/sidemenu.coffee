
views = NS "Pahvi.views"


class views.ToolBox extends Backbone.View

  constructor: ->
    super
    @$el = $ @el

  events:
    "dragstop": "restore"

  restore: ->
    @render()

  render: ->
    @$el.html @renderTemplate "toolbox"
    @$(".addElements .droppable ").draggable
      helper: "clone"
      appendTo: "body"




class views.SideMenu extends Backbone.View


  constructor: ({@settings}) ->
    super
    @$el = $ @el


    @boxProperties = new views.PropertiesManager
      collection: @collection
      settings: @settings

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

    currentView = @subviews[@settings.get("sideMenu") or "toolbox"]
    currentView.render()

    for k, view of @subviews
      view.$el.detach()

    @subviewContainer.html currentView.el

  render: ->
    @$el.html @renderTemplate "sidemenu"
    @subviewContainer = @$(".media")

    @boxProperties.render()
    @$(".boxProperties").html @boxProperties.el

    @renderSubview()

