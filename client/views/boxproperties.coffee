

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
          collection: @collection
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
    if @template
      @$el.html @template @model.toJSON()
    else
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

    $("button.color").tooltip
      effect: "fade",
      position: "center left"




class configs.TextColor extends configs.BackgroundColor
  className: "config colorConfig textColor"
  title: "Text Color"
  colorProperty: "textColor"


class configs.NameEditor extends BaseConfig
  className: "config nameEditor"

  constructor: ->
    super
    @$el = $ @el
    source  = $("#config_nameeditorTemplate").html()
    @template = Handlebars.compile source

  events:
    "keyup input": "_updateId"
    "blur input": "_updateId"

  _updateId: ->
    name = $.trim @input.val()

    if not name or name is @model.get "name"
      return

    if @collection.isUnique "name", name
      @$el.removeClass "invalid"
      @model.set name: name
    else
      @$el.addClass "invalid"

  render: ->
    @$el.html @template
      name: @model.get "name"

    @input = @$("input")

class configs.ImageSrc extends BaseConfig
  className: "config imageSrc"
  title: "Text Color"

  constructor: ->
    super
    @$el = $ @el
    source  = $("#config_imgsrcTemplate").html()
    @template = Handlebars.compile source


  events:
    "blur input": "onKeyUp"

  onKeyUp: ->
    @model.set imgSrc: @$("input").val()




class configs.TextEditor extends BaseConfig

  className: "config texteditor"

  # Override annoying window popup in WYMeditor
  origDialog = WYMeditor.editor.prototype.dialog
  WYMeditor.editor.prototype.dialog = (type) ->

    # Override only for links
    if type isnt WYMeditor.DIALOG_LINK
      return origDialog.apply this, arguments

    wym = this

    selected = wym.selected()
    sStamp = wym.uniqueStamp()
    if selected and selected.tagName and selected.tagName.toLowerCase isnt WYMeditor.A
      selected = jQuery(selected).parentsOrSelf(WYMeditor.A)

    # TODO: prompt is annoying too!
    sUrl = prompt "url", selected[0]?.href

    if sUrl.length > 0

      if selected[0] and selected[0].tagName.toLowerCase() is WYMeditor.A
        link = selected
      else
        wym._exec WYMeditor.CREATE_LINK, sStamp
        link = jQuery "a[href=" + sStamp + "]", wym._doc.body

      link.attr(WYMeditor.HREF, sUrl).attr WYMeditor.TITLE, jQuery(wym._options.titleSelector).val()



  constructor: ->
    super
    source  = $("#config_texteditorTemplate").html()
    @template = Handlebars.compile source



  remove: (ok) ->
    if ok
      @model.set text: @wyn.xhtml()
    super

  _onEditorCreated: ->
    # Remove "1" from heading text since we have only one heading in use
    @$("[name=H1]").text "Heading"
    @$(".wym_tools_html a").click ->
      e = $(".wym_tools_html")
      if e.hasClass("on")
        e.removeClass("on")
      else
        e.addClass("on")

  render: ->
    super

    # http://trac.wymeditor.org/trac/wiki/0.5/Customization
    @$("textarea").wymeditor
      basePath: "/vendor/wymeditor/"
      skinPath: "/vendor/wymeditor/skins/compact/"
      preInit: (wyn) => @wyn = wyn
      postInit: (wyn) => @_onEditorCreated wyn
        
        
      logoHtml: ''
      containersItems: [
        {'name': 'H1', 'title': 'Heading_1', 'css': 'wym_containers_h1'}
        {'name': 'P', 'title': 'Paragraph', 'css': 'wym_containers_p'},
        {'name': 'PRE', 'title': 'Preformatted', 'css': 'wym_containers_pre'},
      ]
      classesHtml: []
      toolsItems: [
        {'name': 'Bold', 'title': 'Strong', 'css': 'wym_tools_strong'},
        {'name': 'Italic', 'title': 'Emphasis', 'css': 'wym_tools_emphasis'},
        {'name': 'CreateLink', 'title': 'Link', 'css': 'wym_tools_link'},
        {'name': 'Unlink', 'title': 'Unlink', 'css': 'wym_tools_unlink'},
        {'name': 'ToggleHtml', 'title': 'HTML', 'css': 'wym_tools_html'},
      ]

    


class configs.FontSize extends BaseConfig
class configs.Border extends BaseConfig
