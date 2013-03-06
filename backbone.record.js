// Generated by CoffeeScript 1.6.1
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
  var Record, contains;
  contains = _arg.contains;
  return Record = (function(_super) {

    __extends(Record, _super);

    function Record() {
      return Record.__super__.constructor.apply(this, arguments);
    }

    Record.prototype.silentUpdate = false;

    Record.prototype.restrictedUpdate = true;

    Record.define = function() {
      var fieldName, recordFields, _i, _len, _results,
        _this = this;
      recordFields = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.prototype.recordFields = recordFields;
      _results = [];
      for (_i = 0, _len = recordFields.length; _i < _len; _i++) {
        fieldName = recordFields[_i];
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
      if (restrictedUpdate) {
        for (k in attrs) {
          v = attrs[k];
          if (k !== 'id' && !contains(this.recordFields, k)) {
            throw new Error("invalid field name '" + k + "' for '" + this.constructor.name + "' record");
          }
        }
      }
      return Record.__super__.set.call(this, attrs, options);
    };

    return Record;

  })(Backbone.Model);
});
