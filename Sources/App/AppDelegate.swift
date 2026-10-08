import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = UIViewController()
        controller.view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        let label = UILabel()
        label.text = "AIR\nBlueLab DSP · AUv3\n\nAbre o AUM e adiciona Air como efeito de áudio.\n\nEsta app instala a extensão AUv3."
        label.numberOfLines = 0; label.textAlignment = .center; label.textColor = .white
        label.font = .systemFont(ofSize: 20); label.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 28),
            label.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -28),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = controller; window?.makeKeyAndVisible()
        return true
    }
}
