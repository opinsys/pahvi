
urlshortener = require "./urlshortener"


# List of non-confusing characters. No "il1o0O".
chars = "abcdefghjkmnopqrstuvwxyz".split("")

randomInt = (min, max) ->
  Math.floor(Math.random() * (max - min + 1)) + min

generateSimpleKey = (size=5) ->
  (chars[randomInt 0, chars.length-1] for i in [1..size]).join ""


class PahviMeta

  constructor: ({@client, @id}) ->

  getRedisId:  -> "pahvi:meta:#{ @id }"

  create: (options, cb) ->
    @client.incr "pahvi:sequence", (err, uniqueNumber) =>
      return cb err if err

      @id = urlshortener.encode uniqueNumber
      console.log options
      ob =
        id: @id
        created: Date.now()
        name: options.name
        contact: options.contact is "ok"
        authKey: generateSimpleKey()

      ob.email or= options.email

      @client.hmset @getRedisId(), ob, (err) ->
        return cb err if err
        cb null, ob

  get: (cb) ->
    @client.hgetall @getRedisId(), (err, result) =>
      return cb err if err

      if not result.id
        return cb
          code: 404
          message: "Unkown pahvi id #{ result.id }"

      cb null, result

  authenticate: (authKey, cb) ->
    if not authKey?
      return cb null, false

    @get (err, result) ->
      return cb err if err
      cb null, authKey is result.authKey


exports.PahviMeta = PahviMeta
