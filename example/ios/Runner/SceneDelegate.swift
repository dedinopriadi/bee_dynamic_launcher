import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      super.scene(scene, willConnectTo: session, options: connectionOptions)
      return
    }
    let window = UIWindow(windowScene: windowScene)
    self.window = window
    let project = FlutterDartProject()
    let controller = FlutterViewController(project: project, nibName: nil, bundle: nil)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
