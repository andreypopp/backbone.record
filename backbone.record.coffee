((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['backbone', 'underscore'], (Backbone, _) ->
      root.Backbone.Record = factory(Backbone, _)
  else if typeof require == 'function' and module?.exports?
    module.exports = factory(require('backbone'), require('underscore'))
  else
    root.Backbone.Record = factory(root.Backbone, root._)
) this, (Backbone, {contains}) ->

  class Record extends Backbone.Model

    silentUpdate: false
    restrictedUpdate: true

    @define: (recordFields...) ->
      this.prototype.recordFields = recordFields
      for fieldName in recordFields
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
          if k != 'id' and not contains(this.recordFields, k)
            throw new Error("invalid field name '#{k}' for '#{this.constructor.name}' record")

      super(attrs, options)
