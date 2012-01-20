

views = NS "Pahvi.views"

configs = NS "Pahvi.configs"

class views.PropertiesManager extends Backbone.View


  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @activeConfigs = []

    @settings.bind "change:activeBox", =>
      @model = @collection.getByCid @settings.get "activeBox"
      @render()


  render: ->
    if not @model
      @$el.empty()
      return

    for config in @activeConfigs
      config.remove()

    @activeConfigs = for configName in @model.configs
      config = new configs[configName]
        model: @model

      config.render()
      @$el.append config.el

      config


class BaseConfig extends Backbone.View

  constructor: ->
    super
    @$el = $ @el

  render: ->
    @$el.html "<div>Config for #{ @constructor.name } is not implemented yet</div>"


class configs.BackgroundColor extends BaseConfig

  className: "config colorConfig backgroundColor"

  colors: [
    [ "Red", "#ff0000" ],
    [ "Green", "#008000" ],
    [ "Blue", "#0000ff" ],
  ]

  title: "Background Color"

  colorProperty: "backgroundColor"


  constructor: ->
    super

    source  = $("#config_colorTemplate").html()
    @template = Handlebars.compile source
    @model.bind "change:#{ @colorProperty }", => @render()

  events:
    "click button": "update"

  update: (e) ->
    ob = {}
    ob[@colorProperty] = $(e.target).data("value")
    @model.set ob

  render: ->
    @$el.html @template
      title: @title
      colors: @colors.map (color) =>
        name: color[0]
        value: color[1]
        current: color[1] is @model.get @colorProperty




class configs.TextColor extends configs.BackgroundColor
  className: "config colorConfig textColor"
  title: "Text Color"
  colorProperty: "textColor"




class configs.FontSize extends BaseConfig
class configs.Rotation extends BaseConfig
class configs.Border extends BaseConfig
