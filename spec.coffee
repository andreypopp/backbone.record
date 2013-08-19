{ok, equal, deepEqual} = require 'assert'
{Collection} = require 'backbone'
{isEmpty} = require 'underscore'
Record = require './index'

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
        birthday: Record.attribute.Number.min(1970)
        email: Record.attribute.String.matches('.+@example.com')

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
          birthday: Record.attribute.Number.min(1970)
          email: Record.attribute.String.matches('.+@example.com')
      user = new User({}, parse: true, validate: true)
      ok user.validationError
      ok user.validationError.birthday
      ok user.validationError.email

    it 'allows to describe optional values', ->
      class User extends Record
        @define
          birthday: Record.attribute.Number.min(1970).optional()
          email: Record.attribute.String.matches('.+@example.com')
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
          a: Record.attribute.Object.oneOf(1, 2, 3)
      ok new Model(a: 1).isValid()
      ok new Model(a: 2).isValid()
      ok new Model(a: 3).isValid()
      ok not new Model(a: 4).isValid()

    describe 'validators', ->

      validate = (validator, value) ->
        isEmpty validator.validate(value)

      describe 'Number', ->

        it 'validates', ->
          ok validate(Record.attribute.Number, 1)
          ok validate(Record.attribute.Number, '1')
          ok not validate(Record.attribute.Number, 'x')

        it 'validates min', ->
          ok validate(Record.attribute.Number.min(0), 1)
          ok validate(Record.attribute.Number.min(0), 0)
          ok not validate(Record.attribute.Number.min(0), -1)

        it 'validates max', ->
          ok validate(Record.attribute.Number.max(1), 1)
          ok validate(Record.attribute.Number.max(0), 0)
          ok not validate(Record.attribute.Number.max(0), 2)

      describe 'String', ->

        it 'validates', ->
          ok validate(Record.attribute.String, 'x')
          ok not validate(Record.attribute.String, 1)

        it 'validates via regexp', ->
          ok validate(Record.attribute.String.matches('[ab]'), 'a')
          ok validate(Record.attribute.String.matches('[ab]'), 'b')
          ok not validate(Record.attribute.String.matches('[ab]'), 'c')

      describe 'oneOf', ->

        it 'validates', ->
          ok validate(Record.attribute.oneOf(1, 2), 1)
          ok validate(Record.attribute.oneOf(1, 2), 2)
          ok not validate(Record.attribute.oneOf(1, 2), 3)

      describe 'Object', ->

        it 'validates', ->
          ok validate(Record.attribute.Object, 1)
          ok not validate(Record.attribute.Object, undefined)
          ok not validate(Record.attribute.Object, null)

        it 'validates optional values', ->
          ok validate(Record.attribute.Object.optional(), undefined)
          ok validate(Record.attribute.Object.optional(), null)

    describe 'validation with nested models', ->

      class Revision extends Record
        @define
          timestamp: Record.attribute.ofType(Date)

      class Revisions extends Collection
        model: Revision

      class Page extends Record
        @define
          lastRevision: Record.attribute.ofType(Revision).optional()
          history: Record.attribute.ofType(Revisions)
          
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
