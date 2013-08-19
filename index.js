// Generated by CoffeeScript 1.6.2
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    return define(['backbone', 'underscore'], function(Backbone, _) {
      return root.Backbone.Record = factory(Backbone, _);
    });
  } else if (typeof require === 'function' && ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null)) {
    return module.exports = factory(require('backbone'), require('underscore'));
  } else {
    return root.Backbone.Record = factory(root.Backbone, root._);
  }
})(this, function(Backbone, _arg) {
  var NumberAttribute, Record, StringAttribute, Validator, contains, createOfType, extend, isEmpty, isFunction, isNaN, isString, _ref, _ref1, _ref2;

  extend = _arg.extend, contains = _arg.contains, isFunction = _arg.isFunction, isEmpty = _arg.isEmpty, isNaN = _arg.isNaN, isString = _arg.isString;
  createOfType = function(type, value) {
    if ((type.prototype.listenTo != null) && (type.prototype.model != null) || (type.prototype.idAttribute != null)) {
      return new type(value, {
        parse: true
      });
    } else {
      return new type(value);
    }
  };
  Record = (function(_super) {
    __extends(Record, _super);

    function Record() {
      _ref = Record.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Record.prototype.silentUpdate = false;

    Record.prototype.restrictedUpdate = true;

    Record.prototype._reservedKeys = ['id', 'cid', 'attributes', 'collection', 'changed', '_changing', '_previousAttributes', '_pending'];

    Record.property = function(name, def) {
      if (isFunction(def)) {
        def = {
          get: def
        };
      }
      return Object.defineProperty(this.prototype, name, def);
    };

    Record.invariant = function(invariant) {
      var _base;

      (_base = this.prototype).invariants || (_base.invariants = []);
      return this.prototype.invariants.push(invariant);
    };

    Record.define = function() {
      var args, k, schema, _i, _len;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 0) {
        throw new Error("invalid schema");
      }
      if (args.length > 1) {
        schema = {};
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          k = args[_i];
          schema[k] = null;
        }
      } else {
        schema = args[0];
      }
      this._defineAccessors(schema);
      this.prototype.schema = schema;
      return this.prototype._schemaKeys = Object.keys(schema);
    };

    Record._defineAccessors = function(schema) {
      var fieldName, _, _results,
        _this = this;

      _results = [];
      for (fieldName in schema) {
        _ = schema[fieldName];
        _results.push((function(fieldName) {
          return Object.defineProperty(_this.prototype, fieldName, {
            get: function() {
              return this.get(fieldName);
            },
            set: function(value) {
              return this.set(fieldName, value, {
                silent: this.silentUpdate
              });
            }
          });
        })(fieldName));
      }
      return _results;
    };

    Record.prototype.parse = function(response, options) {
      var k, result, validator, value, _ref1;

      result = {};
      _ref1 = this.schema;
      for (k in _ref1) {
        validator = _ref1[k];
        value = response[k];
        result[k] = isFunction(validator) ? value != null ? createOfType(validator, value) : void 0 : isFunction(validator.type) ? value != null ? createOfType(validator.type, value) : void 0 : value;
      }
      if (response.id != null) {
        result.id = response.id;
      }
      return result;
    };

    Record.prototype.set = function(key, val, options) {
      var attrs, k, v;

      if (typeof key === 'object') {
        attrs = key;
        options = val;
      } else {
        (attrs = {})[key] = val;
      }
      if (this.restrictedUpdate) {
        for (k in attrs) {
          v = attrs[k];
          if (!contains(this._reservedKeys, k) && !contains(this._schemaKeys, k)) {
            throw new Error("invalid field name '" + k + "' for '" + this.constructor.name + "' record");
          }
        }
      }
      return Record.__super__.set.call(this, attrs, options);
    };

    Record.validate = function(attributes, options) {
      var attrErrors, errors, inv, invErrors, k, v, _i, _len, _ref1, _ref2;

      errors = void 0;
      if (this.prototype.schema) {
        _ref1 = this.prototype.schema;
        for (k in _ref1) {
          v = _ref1[k];
          if (!(isFunction(v.validate))) {
            continue;
          }
          attrErrors = v.validate(attributes[k]);
          if (isEmpty(attrErrors)) {
            continue;
          }
          errors || (errors = {});
          errors[k] = attrErrors;
        }
      }
      if (this.prototype.invariants) {
        _ref2 = this.prototype.invariants;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          inv = _ref2[_i];
          invErrors = inv.call(this, attributes);
          if (isEmpty(invErrors)) {
            continue;
          }
          errors || (errors = {});
          errors.self || (errors.self = []);
          errors.self = errors.self.concat(invErrors);
        }
      }
      return errors;
    };

    Record.prototype.validate = function(attributes, options) {
      return this.constructor.validate(attributes, options);
    };

    return Record;

  })(Backbone.Model);
  Validator = (function() {
    function Validator(options) {
      if (options == null) {
        options = {};
      }
      this.options = options;
      this.type = this.options.type;
    }

    Validator.prototype["new"] = function(options) {
      return new this.constructor(extend({}, this.options, options));
    };

    Validator.prototype.optional = function() {
      return this["new"]({
        optional: true
      });
    };

    Validator.prototype.oneOf = function() {
      var choices;

      choices = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this["new"]({
        choices: choices
      });
    };

    Validator.prototype.ofType = function(type) {
      return this["new"]({
        type: type
      });
    };

    Validator.prototype.validate = function(value) {
      var errors;

      errors = [];
      if (!this.options.optional && (value == null)) {
        errors.push("required");
      }
      if (this.options.choices && !contains(this.options.choices, value)) {
        errors.push("should be one of " + this.options.choices);
      }
      return errors;
    };

    return Validator;

  })();
  NumberAttribute = (function(_super) {
    __extends(NumberAttribute, _super);

    function NumberAttribute() {
      _ref1 = NumberAttribute.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    NumberAttribute.prototype.min = function(min) {
      return this["new"]({
        min: min
      });
    };

    NumberAttribute.prototype.max = function(max) {
      return this["new"]({
        max: max
      });
    };

    NumberAttribute.prototype.validate = function(value) {
      var errors;

      errors = NumberAttribute.__super__.validate.apply(this, arguments);
      if (errors.length > 0 || (value == null)) {
        return errors;
      }
      if (isNaN(Number(value))) {
        return ["should be a number"];
      }
      if ((this.options.min != null) && value < this.options.min) {
        errors.push("" + value + " is less than " + this.options.min + " minimum value");
      }
      if ((this.options.max != null) && value > this.options.max) {
        errors.push("" + value + " is greater than " + this.options.max + " maximum value");
      }
      return errors;
    };

    return NumberAttribute;

  })(Validator);
  StringAttribute = (function(_super) {
    __extends(StringAttribute, _super);

    function StringAttribute() {
      _ref2 = StringAttribute.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    StringAttribute.prototype.matches = function(regexp) {
      if (!(regexp instanceof RegExp)) {
        regexp = RegExp("^" + regexp + "$");
      }
      return this["new"]({
        regexp: regexp
      });
    };

    StringAttribute.prototype.validate = function(value) {
      var errors;

      errors = StringAttribute.__super__.validate.apply(this, arguments);
      if (errors.length > 0 || (value == null)) {
        return errors;
      }
      if (!isString(value)) {
        return ["should be a string"];
      }
      if (this.options.regexp && !this.options.regexp.exec(value)) {
        errors.push("does not match expected pattern " + this.options.regexp);
      }
      return errors;
    };

    return StringAttribute;

  })(Validator);
  return {
    Record: Record,
    attribute: {
      oneOf: function() {
        var args, _ref3;

        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref3 = new Validator).oneOf.apply(_ref3, args);
      },
      ofType: function() {
        var args, _ref3;

        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref3 = new Validator).ofType.apply(_ref3, args);
      },
      Object: new Validator,
      Number: new NumberAttribute,
      String: new StringAttribute
    },
    invariant: {
      requireOneOf: function() {
        var names;

        names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return function(attributes) {
          var name, _i, _len;

          for (_i = 0, _len = names.length; _i < _len; _i++) {
            name = names[_i];
            if (attributes[name] != null) {
              return;
            }
          }
          return ["one of " + (names.join(', ')) + " required"];
        };
      }
    }
  };
});
