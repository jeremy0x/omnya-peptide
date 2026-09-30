import ActivityKit
import Foundation

/// The lock screen Live Activity on shot day. The app keeps it in step with the data:
/// a dose due today and not yet logged shows it, anything else ends it.
@available(iOS 16.2, *)
enum ShotDayActivity {
  static func sync(_ info: [String: Any]?) {
    let current = Activity<ShotDayAttributes>.activities
    guard let info, ActivityAuthorizationInfo().areActivitiesEnabled else {
      for a in current { Task { await a.end(nil, dismissalPolicy: .immediate) } }
      return
    }
    let state = ShotDayAttributes.ContentState(
      compound: info["compound"] as? String ?? "",
      dose: info["dose"] as? String ?? "",
      site: info["site"] as? String ?? ""
    )
    let content = ActivityContent(state: state, staleDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400))
    if let a = current.first {
      Task { await a.update(content) }
    } else {
      _ = try? Activity.request(attributes: ShotDayAttributes(), content: content)
    }
  }
}
