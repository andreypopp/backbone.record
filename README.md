Use with browserify or AMD loader:

    Record = require 'backbone.record'

it generates getters and setters for you:

    class User extends Record
      @define 'username', 'email'

    user = new User

    # calls user.set('username', 'andreypopp')
    # and so fires 'change:username' events
    user.username = 'andreypopp'

    # calls user.get('username')
    console.log(user.username)

    # throws an error cause 'name' attribute wasn't defined
    user.name = 'Andrey Popp'

and provides you with smart `.parse()` implementation which respects nested
models and collections:

    class Address extends Record
      @define 'city', 'street'

    class User extends Record
      @define
        timestamp: Date
        address: Address

    user = new User
      timestamp: '2012-01-01'
      address: {city: 'Moscow', street: 'Tverskaya'}

    assert user.timestamp instanceof Date
    assert user.address instanceof Address
