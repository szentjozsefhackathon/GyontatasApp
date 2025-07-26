import Flutter
import UIKit
import flutter_background_service_ios
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Engedélyezzük a háttérben futó feladatokat
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*10))
    
    // Flutter inicializálás
    GeneratedPluginRegistrant.register(with: self)
    
    // Background szolgáltatás inicializálás
    SwiftFlutterBackgroundServicePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Háttérben történő frissítések kezelése
  override func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("Background fetch started")
    completionHandler(.newData)
  }
}
