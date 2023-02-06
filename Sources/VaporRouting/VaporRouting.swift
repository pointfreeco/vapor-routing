import Vapor

extension Application {
  /// Mounts a router to the Vapor application.
  ///
  /// See ``VaporRouting`` for more information on usage.
  ///
  /// - Parameters:
  ///   - router: A parser-printer that works on inputs of `URLRequestData`.
  ///   - closure: A closure that takes a `Request` and the router's output as arguments.
  public func mount<R: Parser>(
    _ router: R,
    use closure: @escaping (Request, R.Output) async throws -> AsyncResponseEncodable
  ) where R.Input == URLRequestData {
    self.middleware.use(AsyncRoutingMiddleware(router: router, respond: closure))
  }
}

/// Serves requests using a router and response handler.
///
/// You will not typically need to interact with this type directly. Instead you should use the
/// `mount` method on your Vapor application.
///
/// See ``VaporRouting`` for more information on usage.
public struct AsyncRoutingMiddleware<Router: Parser>: AsyncMiddleware
where Router.Input == URLRequestData {
  let router: Router
  let respond: (Request, Router.Output) async throws -> AsyncResponseEncodable

  public func respond(
    to request: Request,
    chainingTo next: AsyncResponder
  ) async throws -> Response {

    if request.body.data == nil {
      try await _ = request.body.collect(max: request.application.routes.defaultMaxBodySize.value)
        .get()
    }

    guard let requestData = URLRequestData(request: request)
    else { return try await next.respond(to: request) }

    let route: Router.Output
    do {
      route = try self.router.parse(requestData)
    } catch let routingError {
      do {
        return try await next.respond(to: request)
      } catch {
        request.logger.info("\(routingError)")

        guard request.application.environment == .development
        else { throw error }

        return Response(status: .notFound, body: .init(string: "Routing \(routingError)"))
      }
    }
    return try await self.respond(request, route).encodeResponse(for: request)
  }
}
