

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


class configs.Color extends BaseConfig
class configs.BackgroundColor extends BaseConfig
class configs.FontSize extends BaseConfig
class configs.Rotation extends BaseConfig
class configs.Border extends BaseConfig
