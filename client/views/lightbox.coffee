
views = NS "Pahvi.views"


class views.Info extends Backbone.View

  constructor: ({@msg, @classes}) ->
    super
    @$el = $ @el

  render: ->
    @$el.html """
      <div class='msgbox #{ @classes }'>#{ @msg }</div>
    """


views.showMessage = (msg) ->
  lb = new views.LightBox
    views: new views.Info
      msg: msg
  lb.renderToBody()


class views.LightBox extends Backbone.View

  className: "lightbox"

  constructor: ({@views}) ->
    super
    @$el = $ @el

    if not _.isArray @views
      @views = [ @views ]

    source  = $("#lightboxTemplate").html()
    @template = Handlebars.compile source


  events:
    "click .close": "close"
    "click": "mightClose"

  mightClose: (e) ->
    if e.target is @el
      @close()

  onOffClick: -> close()

  close: (e) ->
    @trigger "close", this
    e.preventDefault() if e

    for view in @views
      view.remove()

    @remove()


  render: ->
    @$el.html @template()

    viewContainer = @$(".views")
    for view in @views
      view.render()
      viewContainer.append view.el

  renderToBody: ->
    @render()
    $("body").append @el

