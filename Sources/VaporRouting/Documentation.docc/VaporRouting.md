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

In addition to these drawbacks, we often need to be able to generate valid URLs to various server endpoints. For example, suppose we wanted to [generate an HTML page](swift-html-vapor) with a list of all the books for a user, including a link to each book. We have no choice but to manually interpolate a string to form the URL, or build our own ad hoc library of helper functions that do this string interpolation under the hood:

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

## Adding Vapor Routing as a dependency

To use the Vapor Routing library in a SwiftPM project, add it to the dependencies of your Package.swift
and specify the `VaporRouting` product in any targets that need access to the library:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/pointfreeco/vapor-routing", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "<target-name>",
      dependencies: [.product(name: "VaporRouting", package: "vapor-routing")]
    )
  ]
)
```

Vapor Routing provides Vapor bindings to the [URL Routing][swift-url-routing] package.

## Getting started

To use this library, one starts by constructing an enum that describes all the routes your website supports. For example, the book endpoint described above can be represented as a particular case:

```swift
enum SiteRoute {
  case userBook(userId: Int, bookId: Int)
  // more cases for each route
}
```

Then you construct a router, which is an object that is capable of parsing URL requests into `SiteRoute` values and _printing_ `SiteRoute` values back into URL requests. Such routers can be built out of various types the library vends, such as `Path` to match particular path components, `Query` to match particular query items, `Body` to decode request body data, and more:

```swift
import VaporRouting

let siteRouter = OneOf {
  // Maps the URL "/users/:userId/books/:bookId" to the
  // SiteRouter.userBook enum case.
  Route(.case(SiteRouter.userBook)) {
    Path { "users"; Digits(); "books"; Digits() }
  }

  // More uses of Route for each case in SiteRoute
}
```

> Note: Routers are built on top of the [Parsing][swift-parsing] library, which provides a general solution for parsing more nebulous data into first-class data types, like URL requests into your app's routes.

Once this little bit of upfront work is done, using the router doesn't look too dissimilar from using Vapor's native routing tools. First you mount the router to the application to take care of all routing responsibilities, and you do so by providing a closure that transforms `SiteRoute` to a response:

```swift
// configure.swift
public func configure(_ app: Application) throws {
  ...

  app.mount(siteRouter, use: siteHandler)
}

func siteHandler(
  request: Request,
  route: SiteRoute
) async throws -> any AsyncResponseEncodable {
  switch route {
  case .userBook(userId: userId, bookId: bookId):
    async let user = database.fetchUser(user.id)
    async let book = database.fetchBook(book.id)
    return BookResponse(...)

  // more cases...
  }
}
```

Notice that handling the `.userBook` case is entirely focused on just the logic for the endpoint, not parsing and validating the parameters in the URL.

With that done you can now easily generate URLs to any part of your website using a type safe, concise API. For example, generating the list of book links now looks like this:

```swift
Node.ul(
  user.books.map { book in
    .li(
      .a(
        .href(siteRouter.path(for: .userBook(userId: user.id, bookId: book.id)),
        book.title
      )
    )
  }
)
```

Note there is no string interpolation or guessing what shape the path should be in. All of that is handled by the router. We only have to provide the data for the user and book ids, and the router takes care of the rest. If we make a change to the `siteRouter`, such as recognizing the singular form "/user/:userId/book/:bookId", then all paths will automatically be updated. We will not need to search the code base to replace "users" with "user" and "books" with "book".


## Global router

It is best practice to put a router in your global application context rather than reach out to a globally defined router. To do this you can define a `StorageKey` conformance to represent the router's type and add a computed property on Vapor's `Application` type:

```swift
enum SiteRouterKey: StorageKey {
  typealias Value = AnyParserPrinter<URLRequestData, SiteRoute>
}

extension Application {
  var router: SiteRouterKey.Value {
    get {
      self.storage[SiteRouterKey.self]!
    }
    set {
      self.storage[SiteRouterKey.self] = newValue
    }
  }
}
```

Then you can set the router on the application instance handed to your `configure` function:

```swift
// configure.swift
public func configure(_ app: Application) throws {
  ...

  app.router = router
    .eraseToAnyParserPrinter()
  app.mount(app.router, use: siteHandler)
}
```

This is also an appropriate place to configure the base URL of the router so that when you need to generate absolute URLs (_e.g._, for emails) you can do so correctly:

```swift
// configure.swift
public func configure(_ app: Application) throws {
  ...

  app.router = router
    .baseUrl(
      app.environment == .production ? "http://www.mysite.com"
      : app.environment == .staging ? "http://staging.mysite.com"
      : "http://localhost:8080"
    )
    .eraseToAnyParserPrinter()

  app.mount(app.router, use: siteHandler)
}
```

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
