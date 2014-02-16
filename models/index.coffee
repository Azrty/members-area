fs = require 'fs'
require '../env'
async = require 'async'
orm = require 'orm'
orm_timestamps = require 'orm-timestamps'
orm_transaction = require 'orm-transaction'

orm.settings.set 'instance.returnAllErrors', false
orm.settings.set 'properties.required', false

groupErrors = (errors) ->
  errors = [errors] if typeof errors is 'object'
  return null unless errors?.length
  obj = {}
  for error in errors ? []
    obj[error.property] ?= []
    obj[error.property].push error
  return obj

applyCommonClassMethods = (klass) ->
  methods =
    _seed: (callback) ->
      @count().done (err, count) =>
        return callback err if err
        return callback() if count > 0
        # No data, so seed away.
        return callback() unless @seedData
        console.log "Seeding #{model.name}"
        create = (entry, done) =>
          @create(entry).done done
        async.mapSeries @seedData, create, callback
    getLast: ->
      @find
        order: [['id', 'DESC']]
        limit: 1

    groupErrors: groupErrors

  for k, v of methods
    klass[k] = v

validateAndGroup = (name, properties, opts) ->
  opts.methods ?= {}
  opts.methods.groupErrors = groupErrors
  opts.methods.validateAndGroup = (callback) ->
    @validate (err, errors) =>
      return callback err if err
      errors = @groupErrors errors
      callback err, errors

getModelsForConnection = (db, done) ->
  db.use orm_timestamps,
    createdProperty: 'createdAt'
    modifiedProperty: 'updatedAt'
    dbtype: {type: 'date', time: true}
    now: -> new Date()
    persist: true

  db.use orm_transaction

  db.use (db, opts) -> {beforeDefine: validateAndGroup}

  db.applyCommonHooks = (hooks = {}) ->
    return hooks

  fs.readdir __dirname, (err, files) ->
    models = {}
    files.forEach (filename) ->
      [ignore, name, ext] = filename.match /^(.*?)(?:\.(js|coffee))?$/
      return if name is 'index' or name.substr(0,1) is '.'
      return unless ext?.length
      model = require("#{__dirname}/#{name}")(db, models)
      applyCommonClassMethods model
      models[model.modelName] = model

    models.RoleUser.hasOne 'user', models.User, reverse: 'roleUsers'
    models.RoleUser.hasOne 'role', models.Role, reverse: 'roleUsers'

    done null, models

module.exports = getModelsForConnection
expressMiddleware = null # Prevent double initialisation
module.exports.middleware = ->
  expressMiddleware ?= orm.express process.env.DATABASE_URL,
    define: (db, models, next) ->
      getModelsForConnection db, (err, _models) ->
        models[k] = v for own k, v of _models
        next()
  return expressMiddleware
