import Benchmark
import URLRouting
import Vapor
import VaporRouting

let routingSuite = BenchmarkSuite(name: "Routing", settings: MaxIterations(1_000)) { suite in
  LoggingSystem.bootstrap { _ in SwiftLogNoOpLogHandler() }

  let eventLoop = EmbeddedEventLoop()
  var app: Application!
  var req: Request!
  var res: Response!

  struct NoopMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
      request.eventLoop.makeSucceededFuture(.init())
    }
  }

  suite.benchmark("Vapor.baseline") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app.middleware.use(NoopMiddleware())
    req = .init(application: app, method: .GET, url: .init(string: "/"), on: eventLoop)
  } tearDown: {
    app.shutdown()
  }

  suite.benchmark("Vapor.home (no-op)") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(application: app, method: .GET, url: .init(string: "/"), on: eventLoop)
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.home") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(application: app, method: .GET, url: .init(string: "/"), on: eventLoop)
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("Vapor.createUser") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(
      application: app,
      method: .POST,
      url: .init(string: "/users"),
      headers: ["content-type": "application/json"],
      collectedBody: .init(string: #"{"name":"Blob","bio":"Blobbed around the world!"}"#),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.createUser") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(
      application: app,
      method: .POST,
      url: .init(string: "/users"),
      collectedBody: .init(string: #"{"name":"Blob","bio":"Blobbed around the world!"}"#),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("Vapor.fetchUser") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(application: app, method: .GET, url: .init(string: "/users/42"), on: eventLoop)
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.fetchUser") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(application: app, method: .GET, url: .init(string: "/users/42"), on: eventLoop)
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("Vapor.bookSearch") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/search"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.bookSearch") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/search"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("Vapor.bookSearchQuery") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/search?direction=desc&sort=category&count=100"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.bookSearchQuery") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/search?direction=desc&sort=category&count=100"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }


  suite.benchmark("Vapor.fetchUserBook") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    try! routes(app)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/deadbeef-dead-beef-dead-beefdeadbeef"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }

  suite.benchmark("VaporRouting.fetchUserBook") {
    res = try app.responder.respond(to: req).wait()
  } setUp: {
    app = .init()
    app._mount(siteRouter, use: siteHandler)
    req = .init(
      application: app,
      method: .GET,
      url: .init(string: "/users/42/books/deadbeef-dead-beef-dead-beefdeadbeef"),
      on: eventLoop
    )
  } tearDown: {
    precondition(res.status == .ok)
    app.shutdown()
  }
}

struct CreateUser: Codable {
  let bio: String
  let name: String
}
struct SearchOptions: Decodable {
  var sort: Sort = .title
  var direction: Direction = .asc
  var count = 10

  enum Direction: String, CaseIterable, Decodable {
    case asc, desc
  }
  enum Sort: String, CaseIterable, Decodable {
    case title, category
  }
}

@inline(never)
public func blackHole<T>(_ x: T) {}

func routes(_ app: Application) throws {
  app.get { req -> Response in
    return .init()
  }
  app.post("users") { req -> Response in
    blackHole(try req.content.decode(CreateUser.self))
    return .init()
  }
  app.get("users", ":userId") { req -> Response in
    blackHole(try req.parameters.require("userId", as: Int.self))
    return .init()
  }
  app.get("users", ":userId", "books", "search") { req -> Response in
    blackHole(try req.parameters.require("userId", as: Int.self))
    blackHole((try? req.query.get(SearchOptions.Sort.self, at: "sort")) ?? .title)
    blackHole((try? req.query.get(SearchOptions.Direction.self, at: "sort")) ?? .asc)
    blackHole((try? req.query.get(Int.self, at: "count")) ?? 10)
    return .init()
  }
  app.get("users", ":userId", "books", ":bookId") { req -> Response in
    blackHole(try req.parameters.require("userId", as: Int.self))
    blackHole(try req.parameters.require("bookId", as: UUID.self))
    return .init()
  }
}

enum BookRoute {
  case fetch
}
enum BooksRoute {
  case book(UUID, BookRoute = .fetch)
  case search(SearchOptions = .init())
}
enum UserRoute {
  case books(BooksRoute = .search())
  case fetch
}
enum UsersRoute {
  case create(CreateUser)
  case user(Int, UserRoute = .fetch)
}
enum SiteRoute {
  case home
  case users(UsersRoute)
}

let bookRouter = OneOf {
  Route(.case(BookRoute.fetch))
}
let booksRouter = OneOf {
  Route(.case(BooksRoute.search)) {
    Path { From(.utf8) { "search".utf8 } }
    Parse(.memberwise(SearchOptions.init)) {
      Query {
        Field("sort", .string.representing(SearchOptions.Sort.self), default: .title)
        Field("direction", .string.representing(SearchOptions.Direction.self), default: .asc)
        Field("count", default: 10) { Digits() }
      }
    }
  }
  Route(.case(BooksRoute.book)) {
    Path { UUID.parser() }
    bookRouter
  }
}
let userRouter = OneOf {
  Route(.case(UserRoute.fetch))
  Route(.case(UserRoute.books)) {
    Path { From(.utf8) { "books".utf8 } }
    booksRouter
  }
}
let usersRouter = OneOf {
  Route(.case(UsersRoute.create)) {
    Method.post
    Body(.json(CreateUser.self))
  }
  Route(.case(UsersRoute.user)) {
    Path { Digits() }
    userRouter
  }
}
let siteRouter = OneOf {
  Route(.case(SiteRoute.home))
  Route(.case(SiteRoute.users)) {
    Path { From(.utf8) { "users".utf8 } }
    usersRouter
  }
}

func siteHandler(request: Request, route: SiteRoute) -> EventLoopFuture<ResponseEncodable> {
  request.eventLoop.makeSucceededFuture(Response())
}
