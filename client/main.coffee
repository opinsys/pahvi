

views = NS "Example.views"
models = NS "Example.models"

$ ->

  t = new views.TextBox
    name: "Testi"

  $("body").append t.el
  t.render()



