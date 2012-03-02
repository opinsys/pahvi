
fs = require "fs"
path = require "path"

gm = require "gm"


downscale = (width, height, maxWidth) ->
  if width < maxWidth and height < maxWidth
    height = height
    width = width
  else if width > height
    scale = maxWidth / width
    width = maxWidth
    height = height * scale
  else
    scale = maxWidth / height
    height = maxWidth
    width = width * scale

  [width, height]



exports.resize = (inputPath, outputPath, maxWidth, cb) ->

  gm(inputPath).size (err, size) ->

    return cb? err if err

    [width, height] = downscale size.width, size.height, maxWidth

    fs.mkdir path.dirname(outputPath), 0666, (err) ->
      if err and err.code isnt "EEXIST"
        return cb? err

      gm(inputPath).resize(width, height).write outputPath, (err) ->
        cb? err


