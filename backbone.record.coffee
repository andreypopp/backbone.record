((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['backbone', 'underscore'], (Backbone, _) ->
      root.Backbone.Record = factory(Backbone, _)
  else if typeof require == 'function' and module?.exports?
    module.exports = factory(require('backbone'), require('underscore'))
  else
    root.Backbone.Record = factory(root.Backbone, root._)
) this, (Backbone, {contains, isFunction}) ->

  class Record extends Backbone.Model

    silentUpdate: false
    restrictedUpdate: true

    @define: (args...) ->
      if args.length == 0
        throw new Error("invalid schema")

      if args.length > 1
        schema = {}
        for k in args
          schema[k] = null
      else
        schema = args[0]

      this._defineAccessors(schema)
      this._defineParse(schema)
      this.prototype.schema = schema
      this.prototype._schemaKeys = Object.keys(schema)

    @_defineParse: (schema) ->
      this.prototype.parse = (response, options) ->
        result = {}

        for k, v of schema
          result[k] = if isFunction v
            if v::listenTo? and v::model? or v::idAttribute?
              new v(response[k], parse: true)
            else
              new v(response[k])
          else
            response[k]

        if response.id?
          result.id = response.id

        result

    @_defineAccessors: (schema) ->
      for fieldName, _ of schema
        do (fieldName) =>
          Object.defineProperty this.prototype, fieldName,
            get: ->
              this.get(fieldName)
            set: (value) ->
              this.set(fieldName, value, {silent: this.silentUpdate})

    set: (key, val, options) ->
      if (typeof key == 'object')
        attrs = key
        options = val
      else
        (attrs = {})[key] = val

      if this.restrictedUpdate
        for k, v of attrs
          if k != 'id' and not contains(this._schemaKeys, k)
            throw new Error("invalid field name '#{k}' for '#{this.constructor.name}' record")

      super(attrs, options)
