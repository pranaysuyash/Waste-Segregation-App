import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Initialize Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Handle Google Sign-In callback
    if let googleSignIn = NSClassFromString("GIDSignIn") as? NSObjectProtocol,
       googleSignIn.responds(to: Selector(("sharedInstance"))) {
      let sharedInstance = googleSignIn.perform(Selector(("sharedInstance")))?.takeUnretainedValue()
      let handleSelector = Selector(("handleURL:"))
      if let sharedInstance = sharedInstance, sharedInstance.responds(to: handleSelector) {
        let _ = sharedInstance.perform(handleSelector, with: url)
      }
    }
    return super.application(app, open: url, options: options)
  }
}
