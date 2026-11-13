import SwiftUI
import SafariServices

// Clareo is a live, server-backed web app (Firebase Google Sign-In, billing, database) —
// it cannot be bundled offline. SFSafariViewController (real Safari, not an embedded
// WKWebView) is used because Google blocks its Sign-In flow inside plain embedded
// WebViews; Safari View Controller is Apple's and Google's accepted way to host a
// full website as an app's primary content while keeping OAuth sign-in working.
private let clareoURL = URL(string: "https://clareogestion.fr/")!

struct SiteContainerView: UIViewControllerRepresentable {
 func makeUIViewController(context: Context) -> SiteContainerController {
  SiteContainerController()
 }
 func updateUIViewController(_ controller: SiteContainerController, context: Context) {}
}

final class SiteContainerController: UIViewController {
 private var presented = false

 override func viewDidAppear(_ animated: Bool) {
  super.viewDidAppear(animated)
  presentSite()
 }

 private func presentSite() {
  guard !presented else { return }
  presented = true
  let safari = SFSafariViewController(url: clareoURL)
  safari.delegate = self
  safari.dismissButtonStyle = .close
  safari.modalPresentationStyle = .fullScreen
  present(safari, animated: false)
 }
}

extension SiteContainerController: SFSafariViewControllerDelegate {
 // There is nothing to go "back" to behind Safari — represent it instead of leaving a blank screen.
 func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
  presented = false
  presentSite()
 }
}
