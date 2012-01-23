
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
  lb.render()

  $("body").append lb.el

class views.LightBox extends Backbone.View

  className: "lightbox"

  constructor: ({@views}) ->
    if not _.isArray @views
      @views = [ @views ]

    super
    @$el = $ @el

    source  = $("#lightboxTemplate").html()
    @template = Handlebars.compile source

    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @onOffClick(e)

  events:
    "click .close": "close"

  onOffClick: -> close()

  close: (e) ->
    e.preventDefault()
    for view in @views
      view.remove
    @remove()


  render: ->
    @$el.html @template()

    viewContainer = @$(".views")
    for view in @views
      view.render()
      viewContainer.append view.el

