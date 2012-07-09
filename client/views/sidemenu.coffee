
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


    @subviews =
      "toolbox": new views.ToolBox
      "layers": new views.Layers
        collection: @collection
        settings: @settings
      "properties": new views.PropertiesManager
        collection: @collection
        settings: @settings


    @settings.bind "change:sideMenu", => @renderSubview()
    @settings.bind "change:mode", => @render()

  events:
    "click a": "selectSubview"



  selectSubview: (e) ->
    e.preventDefault()
    @$("a").removeClass "active"
    $target = $(e.target).addClass "active"
    @settings.set sideMenu: $target.data("subview")

  renderSubview: ->

    subviewContainer = @$(".scroll")

    for k, view of @subviews
      view.$el.detach()

    for viewName in (@settings.get("sideMenu") or "toolbox properties").split(" ")
      console.info "RENDERING", viewName
      currentView = @subviews[viewName]
      currentView.render()
      subviewContainer.append currentView.el

  render: ->
    @$el.html @renderTemplate "sidemenu"
    @renderSubview()


