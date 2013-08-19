{ok, equal, deepEqual} = require 'assert'
{Collection} = require 'backbone'
{isEmpty} = require 'underscore'
{Record, attribute, invariant} = require './index'

describe 'Backbone.Record', ->

  describe 'schema with just fields', ->

    class M extends Record
      @define 'a', 'b'

    it 'has schema as prototype', ->
      ok M::schema
      deepEqual M::schema, {a: null, b: null}

    it 'defines getters', ->

      class M extends Record
        @define 'a', 'b'

      m = new M(a: 1, b: 2)

      equal m.a, 1
      equal m.a, m.get 'a'
      equal m.b, 2
      equal m.b, m.get 'b'

    it 'defines setters', ->

      m = new M(a: 1, b: 2)

      m.a = 2
      equal m.a, 2
      equal m.a, m.get 'a'

  describe 'complex schema', ->

    class Revision extends Record
      @define
        timestamp: Date

    class Revisions extends Collection
      model: Revision

    class Page extends Record
      @define
        lastRevision: Revision
        history: Revisions

    it 'deserializes complex structures', ->

      p = new Page {
        id: 1
        lastRevision: {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
        history: [
          {id: 'rev1', timestamp: '2011-06-01 12:12:12'},
          {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
        ]
      }, parse: true

      ok p.id
      equal p.id, 1

      ok p.lastRevision
      ok p.lastRevision instanceof Revision
      ok p.lastRevision.timestamp instanceof Date
      equal p.lastRevision.id, 'rev2'

      ok p.history
      ok p.history instanceof Revisions
      equal p.history.length, 2
      ok p.history.at(0) instanceof Revision
      equal p.history.at(0).id, 'rev1'

  describe 'validation', ->

    class User extends Record
      @define
        birthday: attribute.Number.min(1970)
        email: attribute.String.matches('.+@example.com')

    it 'validates on init', ->
      user = new User({birthday: 1969, email: 'andrey'}, parse: true, validate: true)
      ok user.validationError
      ok user.validationError.birthday
      ok user.validationError.email

      user = new User({birthday: 1970, email: 'andrey@example.com'}, parse: true, validate: true)
      ok not user.validationError

    it 'validates on isValid', ->
      user = new User({birthday: 'x', email: 'andrey'}, parse: true)
      ok not user.validationError
      ok not user.isValid()
      ok user.validationError
      ok user.validationError.birthday
      ok user.validationError.email

    it 'treats all attributes as required by default', ->
      class User extends Record
        @define
          birthday: attribute.Number.min(1970)
          email: attribute.String.matches('.+@example.com')
      user = new User({}, parse: true, validate: true)
      ok user.validationError
      ok user.validationError.birthday
      ok user.validationError.email

    it 'allows to describe optional values', ->
      class User extends Record
        @define
          birthday: attribute.Number.min(1970).optional()
          email: attribute.String.matches('.+@example.com')
      user = new User({}, parse: true, validate: true)
      ok user.validationError
      ok not user.validationError.birthday
      ok user.validationError.email
      user = new User({birthday: 1969}, parse: true, validate: true)
      ok user.validationError
      ok user.validationError.birthday
      ok user.validationError.email

    it 'allows "one of" validation', ->
      class Model extends Record
        @define
          a: attribute.Object.oneOf(1, 2, 3)
      ok new Model(a: 1).isValid()
      ok new Model(a: 2).isValid()
      ok new Model(a: 3).isValid()
      ok not new Model(a: 4).isValid()

    describe 'invariants', ->

      class M extends Record
        @define
          a: attribute.Number.min(1).optional()
          b: attribute.Number.max(1).optional()

        @invariant invariant.requireOneOf('a', 'b')

        it 'validates', ->
          m = new M(a: 1, b: 1)
          ok m.isValid()
          m = new M(a: 1)
          ok m.isValid()
          m = new M(b: 1)
          ok m.isValid()
          m = new M()
          ok not m.isValid()
          ok m.validationError.self

    describe 'validators', ->

      validate = (validator, value, isNew) ->
        isEmpty validator.validate(value, isNew)

      describe 'Number', ->

        it 'validates', ->
          ok validate(attribute.Number, 1)
          ok validate(attribute.Number, '1')
          ok not validate(attribute.Number, 'x')

        it 'validates min', ->
          ok validate(attribute.Number.min(0), 1)
          ok validate(attribute.Number.min(0), 0)
          ok not validate(attribute.Number.min(0), -1)

        it 'validates max', ->
          ok validate(attribute.Number.max(1), 1)
          ok validate(attribute.Number.max(0), 0)
          ok not validate(attribute.Number.max(0), 2)

      describe 'String', ->

        it 'validates', ->
          ok validate(attribute.String, 'x')
          ok not validate(attribute.String, 1)

        it 'validates via regexp', ->
          ok validate(attribute.String.matches('[ab]'), 'a')
          ok validate(attribute.String.matches('[ab]'), 'b')
          ok not validate(attribute.String.matches('[ab]'), 'c')

      describe 'oneOf', ->

        it 'validates', ->
          ok validate(attribute.oneOf(1, 2), 1)
          ok validate(attribute.oneOf(1, 2), 2)
          ok not validate(attribute.oneOf(1, 2), 3)

      describe 'Object', ->

        it 'validates', ->
          ok validate(attribute.Object, 1)
          ok not validate(attribute.Object, undefined)
          ok not validate(attribute.Object, null)

        it 'validates optional values', ->
          ok validate(attribute.Object.optional(), undefined)
          ok validate(attribute.Object.optional(), null)

        it 'validates optional values for isNew state', ->
          ok validate(attribute.Object.optionalWhenNew(), undefined, true)
          ok validate(attribute.Object.optionalWhenNew(), null, true)
          ok validate(attribute.Object.optional(), undefined, true)
          ok validate(attribute.Object.optional(), null, true)
          ok validate(attribute.Object.optional(), undefined, false)
          ok validate(attribute.Object.optional(), null, false)
          ok not validate(attribute.Object.optionalWhenNew(), undefined, false)
          ok not validate(attribute.Object.optionalWhenNew(), null, false)

    describe 'validation with nested models', ->

      class Revision extends Record
        @define
          timestamp: attribute.ofType(Date)

      class Revisions extends Collection
        model: Revision

      class Page extends Record
        @define
          lastRevision: attribute.ofType(Revision).optional()
          history: attribute.ofType(Revisions)
          
      it 'deserializes complex structures', ->

        p = new Page {
          id: 1
          lastRevision: {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
          history: [
            {id: 'rev1', timestamp: '2011-06-01 12:12:12'},
            {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
          ]
        }, parse: true

        ok p.id
        equal p.id, 1

        ok p.lastRevision
        ok p.lastRevision instanceof Revision
        ok p.lastRevision.timestamp instanceof Date
        equal p.lastRevision.id, 'rev2'

        ok p.history
        ok p.history instanceof Revisions
        equal p.history.length, 2
        ok p.history.at(0) instanceof Revision
        equal p.history.at(0).id, 'rev1'

      it 'validates', ->
        p = new Page {
          id: 1
          lastRevision: {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
          history: [
            {id: 'rev1', timestamp: '2011-06-01 12:12:12'},
            {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
          ]
        }, parse: true
        ok p.isValid()

        p = new Page {
          id: 1
          lastRevision: {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
          history: []
        }, parse: true
        ok p.isValid()

        p = new Page {
          id: 1
          lastRevision: {id: 'rev2', timestamp: '2011-06-01 12:12:12'}
        }, parse: true
        ok not p.isValid()
        ok p.validationError.history
        ok not p.validationError.lastRevision

        p = new Page {
          id: 1
          history: []
        }, parse: true
        ok p.isValid()
