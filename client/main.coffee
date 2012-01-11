

views = NS "Example.views"
models = NS "Example.models"

$ ->

  store = new models.Store
    name: "example"

  editor = new views.Editor
    name: "Example Editor"
    el: ".widgets. .editor"
    model: store


  preview = new views.Preview
    name: "Example"
    el: ".widgets. .preview"
    model: store


  editor.render()
  preview.render()
