

views = NS "Pahvi.views"
configs = NS "Pahvi.configs"
t = NS "Pahvi.translate"

class views.PropertiesManager extends Backbone.View

  className: "boxProperties"

  constructor: ({@settings}) ->
    super
    @$el = $ @el


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

    @$el.html @renderTemplate "boxproperties", active: !!@model

    @configContainer = @$(".configs")

    for config in @activeConfigs
      config.render()
      @configContainer.append config.el


class BaseConfig extends Backbone.View

  templateId: null

  constructor: ->
    super
    @$el = $ @el

  render: ->
    if @templateId
      @$el.html @renderTemplate @templateId, @model.toJSON()
    else
      @$el.html "<div>Config for #{ @constructor.name } is not implemented yet</div>"


class configs.BackgroundColor extends BaseConfig

  className: "config colorConfig backgroundColor"
  colorProperty: "backgroundColor"
  templateId: "config_color"

  title: t "boxproperties.backgroundColor.title"


  update: (color, localOnly) ->
    ob = {}
    ob[@colorProperty] = color
    console.info "Setting #{ ob[@colorProperty] } with #{ localOnly }"
    @model.set ob, local: localOnly


  render: ->

    @$el.html @renderTemplate @templateId,
      title: @title

    @joe?.removeAllListeners()

    joe = @joe = colorjoe.rgb(
      @$(".colorWidgetContainer").get(0),
      @model.get(@colorProperty) or "white"
    )

    @joe.on "change", (color) => @update color.css(), true
    @joe.on "done", (color) =>
      @update "black", true
      @update color.css(), false





class configs.TextColor extends configs.BackgroundColor
  className: "config colorConfig textColor"
  colorProperty: "textColor"

  title: t "boxproperties.textColor.title"

class configs.NameEditor extends BaseConfig
  className: "config nameEditor"

  templateId: "config_nameeditor"


  constructor: ->
    super
    @$el = $ @el

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
    @$el.html @renderTemplate @templateId,
      name: @model.get "name"

    @input = @$("input")

class configs.ImageSrc extends BaseConfig
  className: "config imageSrc"
  title: "Text Color"

  templateId: "config_imgsrc"

  constructor: ->
    super
    @$el = $ @el


  events:
    "blur input": "setImageSrc"
    "keyup input": "_onKeyUp"
    "change .fileInput": "_onFileSelected"

  _onFileSelected: (e) ->
    file = e.target.files[0]
    upload = new views.Upload
      model: @model
      file: file
    upload.renderToBody()
    upload.start()

  _onKeyUp: (e) ->
    # If user hits enter
    if e.which is 13
      @setImageSrc()

  setImageSrc: ->
    @model.set imgSrc: @$("input").val()




class configs.TextEditor extends BaseConfig

  className: "config texteditor"

  templateId: "config_texteditor"

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
    sUrl = prompt "url", if selected[0]?.href then selected[0]?.href else "http://"

    if sUrl.length > 0

      if selected[0] and selected[0].tagName.toLowerCase() is WYMeditor.A
        link = selected
      else
        wym._exec WYMeditor.CREATE_LINK, sStamp
        link = jQuery "a[href=" + sStamp + "]", wym._doc.body

      link.attr(WYMeditor.HREF, sUrl).attr WYMeditor.TITLE, jQuery(wym._options.titleSelector).val()



  remove: (ok) ->
    if ok
      @model.set text: @wyn.xhtml()
    super

  _onEditorCreated: ->
    # Remove "1" from heading text since we have only one heading in use
    @$("[name=H1]").text "H1"
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
        {'name': 'InsertOrderedList', 'title': 'Ordered_List', 'css': 'wym_tools_ordered_list'},
        {'name': 'InsertUnorderedList', 'title': 'Unordered_List', 'css': 'wym_tools_unordered_list'},
        {'name': 'ToggleHtml', 'title': 'HTML', 'css': 'wym_tools_html'},
      ]




class configs.FontSize extends BaseConfig
class configs.Border extends BaseConfig
