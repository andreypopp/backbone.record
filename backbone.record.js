// Generated by CoffeeScript 1.6.3
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
  var Record, contains, isFunction, _ref;
  contains = _arg.contains, isFunction = _arg.isFunction;
  return Record = (function(_super) {
    __extends(Record, _super);

    function Record() {
      _ref = Record.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Record.prototype.silentUpdate = false;

    Record.prototype.restrictedUpdate = true;

    Record.property = function(name, def) {
      if (isFunction(def)) {
        def = {
          get: def
        };
      }
      return Object.defineProperty(this.prototype, name, def);
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
      this._defineParse(schema);
      this.prototype.schema = schema;
      return this.prototype._schemaKeys = Object.keys(schema);
    };

    Record._defineParse = function(schema) {
      return this.prototype.parse = function(response, options) {
        var k, result, v;
        result = {};
        for (k in schema) {
          v = schema[k];
          result[k] = isFunction(v) ? response[k] == null ? null : (v.prototype.listenTo != null) && (v.prototype.model != null) || (v.prototype.idAttribute != null) ? new v(response[k], {
            parse: true
          }) : new v(response[k]) : response[k];
        }
        if (response.id != null) {
          result.id = response.id;
        }
        return result;
      };
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
          if (k !== 'id' && !contains(this._schemaKeys, k)) {
            throw new Error("invalid field name '" + k + "' for '" + this.constructor.name + "' record");
          }
        }
      }
      return Record.__super__.set.call(this, attrs, options);
    };

    return Record;

  })(Backbone.Model);
});
