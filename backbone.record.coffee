((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['backbone', 'underscore'], (Backbone, _) ->
      root.Backbone.Record = factory(Backbone, _)
  else if typeof require == 'function' and module?.exports?
    module.exports = factory(require('backbone'), require('underscore'))
  else
    root.Backbone.Record = factory(root.Backbone, root._)
) this, (Backbone, _) ->

  class Record extends Backbone.Model

    silentUpdate: false

    @define: (recordFields...) ->
      this.prototype.recordFields = recordFields
      for fieldName in recordFields
        do (fieldName) =>
          Object.defineProperty this.prototype, fieldName,
            get: ->
              this.get(fieldName)
            set: (value) ->
              this.set(fieldName, value, {silent: this.silentUpdate})

    set: (name, value, options) ->
      if not (name of this.recordFields)
        throw new Error("invalid field name '#{name}' for '#{this.constructor.name}' record")
      super
