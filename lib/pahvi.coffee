
urlshortener = require "./urlshortener"


class PahviMeta

  constructor: ({@client}) ->


  toRedisId: (id) -> "pahvi-#{ id }"

  create: (options, cb) ->
    @client.incr "pahvi_sequence", (err, uniqueNumber) =>
      return cb err if err

      id = urlshortener.encode uniqueNumber
      ob =
        id: id
        name: options.name
        email: options.email
        authKey: "#{ S4() }-#{ S4() }-#{ S4() }"

      client.hmset @toRedisId(id), ob, (err) ->
        return cb err if err
        cb null, ob

  get: (id, cb) ->
    @client.hgetall @toRedisId(id), (err, result) =>
      throw err if err # TODO

      if not result.id
        return cb
          code: 404
          message: "Unkown pahvi id #{ id }"

      cb null, result

  authenticate: (id, authKey, cb) ->
    if not authKey?
      return cb null, false

    @get id, (err, result) ->
      return cb err if err
      cb null, authKey is result.authKey


exports.PahviMeta = PahviMeta
