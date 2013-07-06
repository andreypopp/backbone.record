{ok, equal, deepEqual} = require 'assert'
{Collection} = require 'backbone'
Record = require './backbone.record'

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
