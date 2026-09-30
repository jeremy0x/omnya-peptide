import ActivityKit
import Foundation

/// Shared by the app (which starts the activity) and the widget extension (which draws it).
struct ShotDayAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var compound: String
    var dose: String
    var site: String
  }
}
