

views = NS "Pahvi.views"

configs = NS "Pahvi.configs"

class views.PropertiesManager extends Backbone.View


  constructor: ({@settings}) ->
    super
    @$el = $ @el

    source  = $("#boxpropertiesTemplate").html()
    @template = Handlebars.compile source

    @activeConfigs = []

    @settings.bind "change:activeBox", =>
      @model = @collection.get @settings.get "activeBox"
      @render()


  render: ->

    for config in @activeConfigs
      config.remove()

    if not @model
      @activeConfigs = []
    else
      @activeConfigs = for configName in @model.configs
        config = new configs[configName]
          model: @model
        config.render()
        config

    @$el.html @template active: !!@model

    @configContainer = @$(".configs")

    for config in @activeConfigs
      config.render()
      @configContainer.append config.el


class BaseConfig extends Backbone.View

  constructor: ->
    super
    @$el = $ @el

  render: ->
    @$el.html "<div>Config for #{ @constructor.name } is not implemented yet</div>"


class configs.BackgroundColor extends BaseConfig

  className: "config colorConfig backgroundColor"

  colors: [
    [ "Transparent", "transparent" ],
    [ "Red", "#ff0000" ],
    [ "Green", "#008000" ],
    [ "Blue", "#0000ff" ],
    [ "White", "#ffffff" ],
    [ "Pahvi Yellow", "#fffdf1" ],
    [ "Pahvi Cream", "#f5f4f0" ],
    [ "Gray", "#c2c2c2" ],
    [ "Pahvi Gray", "#363636" ],
    [ "Black", "#000000" ],
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
        transparent: color[1] is "transparent"
        current: color[1] is @model.get @colorProperty




class configs.TextColor extends configs.BackgroundColor
  className: "config colorConfig textColor"
  title: "Text Color"
  colorProperty: "textColor"



class configs.ImageSrc extends BaseConfig
  className: "config imageSrc"
  title: "Text Color"

  constructor: ->
    super
    source  = $("#config_imgsrcTemplate").html()
    @template = Handlebars.compile source


  events:
    "blur input": "onKeyUp"

  onKeyUp: ->
    @model.set imgSrc: @$("input").val()

  render: ->
    @$el.html @template @model.toJSON()




class configs.FontSize extends BaseConfig
class configs.Border extends BaseConfig
