# ``VaporRouting``

A bidirectional Vapor router with more type safety and less fuss.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/vapor-routing)
- [Discussions](https://github.com/pointfreeco/vapor-routing/discussions)
- [Point-Free Video][vapor-routing-video]

## Motivation

Routing in [Vapor][vapor] has a simple API that is similar to popular web frameworks in other languages, such as Ruby's [Sinatra][sinatra] or Node's [Express][express]. It works well for simple routes, but complexity grows over time due to lack of type safety and the inability to _generate_ correct URLs to pages on your site.

To see this, consider an endpoint to fetch a book that is associated with a particular user:

```swift
// GET /users/:userId/books/:bookId
app.get("users", ":userId", "books", ":bookId") { req -> BooksResponse in
  guard
    let userId = req.parameters.get("userId", Int.self),
    let bookId = req.parameters.get("bookId", Int.self)
  else {
    struct BadRequest: Error {}
    throw BadRequest()
  }

  // Logic for fetching user and book and constructing response...
  async let user = database.fetchUser(user.id)
  async let book = database.fetchBook(book.id)
  return BookResponse(...)
}
```

When a URL request is made to the server whose method and path matches the above pattern, the closure will be executed for handling that endpoint's logic.

Notice that we must sprinkle in validation code and error handling into the endpoint's logic in order to coerce the stringy parameter types into first class data types. This obscures the real logic of the endpoint, and any changes to the route's pattern must be kept in sync with the validation logic, such as if we rename the `:userId` or `:bookId` parameters.

In addition to these drawbacks, we often need to be able to generate valid URLs to various server endpoints. For example, suppose we wanted to [generate an HTML page][swift-html-vapor] with a list of all the books for a user, including a link to each book. We have no choice but to manually interpolate a string to form the URL, or build our own ad hoc library of helper functions that do this string interpolation under the hood:

```swift
Node.ul(
  user.books.map { book in
    .li(
      .a(.href("/users/\(user.id)/book/\(book.id)"), book.title)
    )
  }
)
```
```html
<ul>
  <li><a href="/users/42/book/321">Blob autobiography</a></li>
  <li><a href="/users/42/book/123">Life of Blob</a></li>
  <li><a href="/users/42/book/456">Blobbed around the world</a></li>
</ul>
```

It is our responsibility to make sure that this interpolated string matches exactly what was specified in the Vapor route. This can be tedious and error prone.

In fact, there is a typo in the above code. The URL constructed goes to "/book/:bookId", but really it should be "/book*s*/:bookId":

```diff
- .a(.href("/users/\(user.id)/book/\(book.id)"), book.title)
+ .a(.href("/users/\(user.id)/books/\(book.id)"), book.title)
```

This library aims to solve these problems, and more, when dealing with routing in a Vapor application.

## Topics

### Articles

* ``GettingStarted``

## See Also

A free video from [Point-Free](https://www.pointfree.co) demonstrating how to use the vapor-routing library:

* [Point-Free Video][vapor-routing-video]

[vapor-routing-docs]: https://pointfreeco.github.io/vapor-routing
[vapor]: http://vapor.codes
[swift-url-routing]: http://github.com/pointfreeco/swift-url-routing
[swift-parsing]: http://github.com/pointfreeco/swift-parsing
[swift-html-vapor]: https://github.com/pointfreeco/swift-html-vapor
[express]: http://expressjs.com
[sinatra]: http://sinatrarb.com
[vapor-routing-video]: http://pointfree.co/episodes/ep188-tour-of-parser-printers-vapor-routing
