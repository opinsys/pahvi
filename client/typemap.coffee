
views = NS "Pahvi.views"
models = NS "Pahvi.models"

# Create model/view/configure mapping of available Box types.  Box Models,
# Views and Configure views are connected together by their `type` property.
# This will go through those and creates `Boxes.types` mapping for them.
# Later this can be used to get corresponding View/Model/CongigureView
Pahvi.typeMapping = {}
typeSources =
  Model: models
  View: views
for metaClassName, namespace of typeSources
  for __, metaClass of namespace when metaClass.prototype?.type
    Pahvi.typeMapping[metaClass.prototype.type] ?= {}
    Pahvi.typeMapping[metaClass.prototype.type][metaClassName] = metaClass
