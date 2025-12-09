import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Flutter engine first
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Force load plugin frameworks to ensure Swift runtime is initialized
    // This prevents crashes when accessing Swift type metadata
    if let pathProviderFramework = Bundle.main.path(forResource: "path_provider_foundation", ofType: "framework") {
      Bundle(path: pathProviderFramework)?.load()
    }
    if let sharedPrefsFramework = Bundle.main.path(forResource: "shared_preferences_foundation", ofType: "framework") {
      Bundle(path: sharedPrefsFramework)?.load()
    }
    
    // Now register plugins - Swift runtime should be ready
    GeneratedPluginRegistrant.register(with: self)
    
    return result
  }
}
