import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
        fatalError("Not found: '/path/to/.env'.\nPlease create .env file reference from .env.sample")
    }
    let url = URL(fileURLWithPath: path)
    do {
        let data = try Data(contentsOf: url)
        let str = String(data: data, encoding: .utf8) ?? "Empty File"
        let clean = str.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
        let envVars = clean.components(separatedBy:"\n")
        for envVar in envVars {
            let keyVal = envVar.components(separatedBy:"=")
            if keyVal.count == 2 {
                setenv(keyVal[0], keyVal[1], 1)
            }
        }
        let env = ProcessInfo.processInfo.environment
        GMSServices.provideAPIKey(env["API_Key"]!)
    } catch {
        fatalError(error.localizedDescription)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
