((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['backbone', 'underscore'], (Backbone, _) ->
      root.Backbone.Record = factory(Backbone, _)
  else if typeof require == 'function' and module?.exports?
    module.exports = factory(require('backbone'), require('underscore'))
  else
    root.Backbone.Record = factory(root.Backbone, root._)
) this, (Backbone, {extend, contains, isFunction, isEmpty, isNaN, isString}) ->

  createOfType = (type, value) ->
    if type::listenTo? and type::model? or type::idAttribute?
      new type(value, parse: true)
    else
      new type(value)

  class Record extends Backbone.Model

    silentUpdate: false
    restrictedUpdate: true
    _reservedKeys: [
      'id', 'cid', 'attributes', 'collection', 'changed',
      '_changing', '_previousAttributes', '_pending']

    @property: (name, def) ->
      def = {get: def} if isFunction def
      Object.defineProperty this.prototype, name, def

    @invariant: (invariant) ->
      this::invariants or= []
      this::invariants.push invariant

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
      this::schema = schema
      this::_schemaKeys = Object.keys(schema)

    @_defineAccessors: (schema) ->
      for fieldName, _ of schema
        do (fieldName) =>
          Object.defineProperty this.prototype, fieldName,
            get: ->
              this.get(fieldName)
            set: (value) ->
              this.set(fieldName, value, {silent: this.silentUpdate})

    parse: (response, options) ->
      result = {}

      for k, validator of this.schema
        value = response[k]
        result[k] = if isFunction validator
          createOfType(validator, value) if value?
        else if isFunction validator.type
          createOfType(validator.type, value) if value?
        else
          value

      if response.id?
        result.id = response.id

      result

    set: (key, val, options) ->
      if (typeof key == 'object')
        attrs = key
        options = val
      else
        (attrs = {})[key] = val

      if this.restrictedUpdate
        for k, v of attrs
          if not contains(this._reservedKeys, k) and not contains(this._schemaKeys, k)
            throw new Error("invalid field name '#{k}' for '#{this.constructor.name}' record")

      super(attrs, options)

    @validate: (attributes, options) ->
      errors = undefined

      if this::schema
        for k, v of this::schema when isFunction v.validate
          attrErrors = v.validate attributes[k]
          continue if isEmpty attrErrors
          errors or= {}
          errors[k] = attrErrors

      if this::invariants
        for inv in this::invariants
          invErrors = inv.call(this, attributes)
          continue if isEmpty invErrors
          errors or= {}
          errors.self or= []
          errors.self = errors.self.concat invErrors

      errors

    validate: (attributes, options) ->
      this.constructor.validate(attributes, options)

  class Validator

    constructor: (options = {}) ->
      this.options = options
      this.type = this.options.type

    new: (options) ->
      new this.constructor(extend {}, this.options, options)

    optional: ->
      this.new {optional: true}

    oneOf: (choices...) ->
      this.new {choices: choices}

    ofType: (type) ->
      this.new {type: type}

    validate: (value) ->
      errors = []
      if not this.options.optional and not value?
        errors.push "required"
      if this.options.choices and not contains this.options.choices, value
        errors.push "should be one of #{this.options.choices}"
      errors

  class NumberAttribute extends Validator

    min: (min) ->
      this.new {min}

    max: (max) ->
      this.new {max}

    validate: (value) ->
      errors = super
      return errors if errors.length > 0 or not value?
      if isNaN Number value
        return ["should be a number"]
      if this.options.min? and value < this.options.min
        errors.push "#{value} is less than #{this.options.min} minimum value"
      if this.options.max? and value > this.options.max
        errors.push "#{value} is greater than #{this.options.max} maximum value"
      errors

  class StringAttribute extends Validator

    matches: (regexp) ->
      regexp = ///^#{regexp}$/// unless regexp instanceof RegExp
      this.new {regexp}

    validate: (value) ->
      errors = super
      return errors if errors.length > 0 or not value?
      if not isString value
        return ["should be a string"]
      if this.options.regexp and not this.options.regexp.exec value
        errors.push "does not match expected pattern #{this.options.regexp}"
      errors

  Record: Record
  attribute:
    oneOf: (args...) -> (new Validator).oneOf(args...)
    ofType: (args...) -> (new Validator).ofType(args...)
    Object: new Validator
    Number: new NumberAttribute
    String: new StringAttribute
  invariant:
    requireOneOf: (names...) ->
      (attributes) ->
        for name in names
          return if attributes[name]?
        ["one of #{names.join(', ')} required"]
