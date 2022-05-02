# Getting Started

How to add Vapor Routing to your application and start using it immediately.

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

## Using Vapor Routing in your web application

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

With that done you can access the application's router through the request object that is handed to your handler:

```swift
func siteHandler(
  request: Request,
  route: SiteRoute
) async throws -> any AsyncResponseEncodable {
  
  request.application.router.path(for: .userBook(userId: 42, bookId: 123)) // "/users/42/books/123""
}
```

[swift-url-routing]: http://github.com/pointfreeco/swift-url-routing
[swift-parsing]: http://github.com/pointfreeco/swift-parsing
