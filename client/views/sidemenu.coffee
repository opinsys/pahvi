
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
    "click .closeOpenMediamenuBtn": "toggleOpen"

  toggleOpen: ->

    if @$el.hasClass "open"
      @$el.removeClass "open"
      @$el.addClass "closed"
    else
      @$el.removeClass "closed"
      @$el.addClass "open"

    movement = 0
    # CSS property 'right' is 0px when side menu is open
    if parseInt(@$el.css('right'), 10) is 0
      movement =  @$el.outerWidth() * -1

    # When we want to close the menu we set it move off screen 
    @$el.animate
      right: movement


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

