import Foundation
import Vapor
import VaporRouting

enum SiteRoute: Equatable {
  case home
  case contactUs
  case episodes(EpisodesRoute)
}
enum EpisodesRoute: Equatable {
  case index
  case episode(id: Int, route: EpisodeRoute)
}
enum EpisodeRoute: Equatable {
  case show
  case comments(CommentsRoute)
}
enum CommentsRoute: Equatable {
  case post(Comment)
  case show(count: Int)
}
struct Comment: Codable, Content, Equatable {
  let commenter: String
  let message: String
}

let commentsRouter = OneOf {
  Route(.case(CommentsRoute.post)) {
    Method.post
    Body(.json(Comment.self, encoder: JSONEncoder()))
  }

  Route(.case(CommentsRoute.show)) {
    Query {
      Field("count", default: 10) { Digits() }
    }
  }
}

let episodeRouter = OneOf {
  Route(EpisodeRoute.show)

  Route(.case(EpisodeRoute.comments)) {
    Path { From(.utf8) { "comments".utf8 } }

    commentsRouter
  }
}

let episodesRouter = OneOf {
  Route(EpisodesRoute.index)

  Route(.case(EpisodesRoute.episode)) {
    Path { Digits() }

    episodeRouter
  }
}

let siteRouter = OneOf {
  Route(SiteRoute.home)

  Route(SiteRoute.contactUs) {
    Path { From(.utf8) { "contact-us".utf8 } }
  }

  Route(.case(SiteRoute.episodes)) {
    Path { From(.utf8) { "episodes".utf8 } }

    episodesRouter
  }
}
