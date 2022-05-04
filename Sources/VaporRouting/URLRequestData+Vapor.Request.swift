import Foundation
import URLRouting
import Vapor

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension URLRequestData {
  /// Initializes parseable request data from a Vapor request.
  ///
  /// - Parameter request: A Vapor request.
  public init?(request: Vapor.Request) {
    guard
      let url = URL(string: request.url.string),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return nil }

    let body: Data?
    if var buffer = request.body.data,
      let bytes = buffer.readData(length: buffer.readableBytes)
    {
      body = bytes
    } else {
      body = nil
    }

    self.init(
      method: request.method.string,
      scheme: components.scheme,
      user: request.headers.basicAuthorization?.username,
      password: request.headers.basicAuthorization?.password,
      host: components.host,
      port: components.port,
      path: components.path,
      query: components.queryItems?.reduce(into: [:]) { query, item in
        query[item.name, default: []].append(item.value)
      } ?? [:],
      headers: Dictionary(
        request.headers.map { key, value in
          (
            key,
            value.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
          )
        },
        uniquingKeysWith: { $0 + $1 }
      ),
      body: body
    )
  }
}
