import Foundation
import Vapor
import URLRouting

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

    let body: [UInt8]?
    if var buffer = request.body.data,
      let bytes = buffer.readBytes(length: buffer.readableBytes)
    {
      body = bytes
    } else {
      body = nil
    }

    self.init(
      method: request.method.string,
      scheme: request.url.scheme,
      user: request.headers.basicAuthorization?.username,
      password: request.headers.basicAuthorization?.password,
      host: request.url.host,
      port: request.url.port,
      path: request.url.path,
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
      body: body.map { Data($0) }
    )
  }
}
