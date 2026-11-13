import SwiftUI

@main
struct ClareoApp: App {
 var body: some Scene {
  WindowGroup {
   SiteContainerView()
    .ignoresSafeArea()
    .statusBar(hidden: false)
  }
 }
}
