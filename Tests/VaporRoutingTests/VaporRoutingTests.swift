import VaporRouting
import XCTVapor
import XCTest

final class VaporRoutingTests: XCTestCase {
  func testGetComments() throws {
    let app = Application(.testing)
    defer { app.shutdown() }

    app.mount(siteRouter) { _, route in
      switch route {
      case .episodes(.episode(id: 42, route: .comments(.show(count: 100)))):
        return "Comments"
      default:
        return Response(status: .badRequest)
      }
    }

    try app.test(.GET, "/episodes/42/comments?count=100") { response in
      XCTAssertEqual(response.status, .ok)
      try XCTAssertEqual(response.content.decode(String.self), "Comments")
    }
  }

  func testPostComment() throws {
    let app = Application(.testing)
    defer { app.shutdown() }

    app.mount(siteRouter) { _, route in
      switch route {
      case .episodes(
        .episode(id: 42, route: .comments(.post(.init(commenter: "Blob", message: "Good job!"))))):
        return "Post comment"

      default:
        return Response(status: .badRequest)
      }
    }

    try app.test(
      .POST,
      "/episodes/42/comments",
      beforeRequest: { req in
        try req.content.encode(Comment(commenter: "Blob", message: "Good job!"))
      },
      afterResponse: { response in
        XCTAssertEqual(response.status, .ok)
        try XCTAssertEqual(response.content.decode(String.self), "Post comment")
      }
    )
  }
}
