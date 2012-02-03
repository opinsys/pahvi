
urlshortener = require "./urlshortener"

S4 = -> (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)

class PahviMeta

  constructor: ({@client, @id}) ->

  getRedisId:  -> "pahvi-#{ @id }"

  create: (options, cb) ->
    @client.incr "pahvi_sequence", (err, uniqueNumber) =>
      return cb err if err

      @id = urlshortener.encode uniqueNumber
      console.log options
      ob =
        id: @id
        created: Date.now()
        name: options.name
        email: options.email
        contact: options.contact is "ok"
        authKey: "#{ S4() }-#{ S4() }-#{ S4() }"

      @client.hmset @getRedisId(), ob, (err) ->
        return cb err if err
        cb null, ob

  get: (cb) ->
    @client.hgetall @getRedisId(), (err, result) =>
      return cb err if err

      if not result.id
        return cb
          code: 404
          message: "Unkown pahvi id #{ id }"

      cb null, result

  authenticate: (authKey, cb) ->
    if not authKey?
      return cb null, false

    @get (err, result) ->
      return cb err if err
      cb null, authKey is result.authKey


exports.PahviMeta = PahviMeta
