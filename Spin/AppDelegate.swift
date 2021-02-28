import ImageIO
import MobileCoreServices
import QuartzCore
import UIKit

// MARK: - Boilerplate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}
}

// MARK: - More Boilerplate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
}

// MARK: - Being Difficult

infix operator %

func %(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
	lhs.truncatingRemainder(dividingBy: rhs)
}

// MARK: - The Fun Part

class View: UIView {
	static let font = UIFont.systemFont(ofSize: 96, weight: .black)
	static let width: CGFloat = 128
	static let height: CGFloat = 114

	let background: UILabel = {
		let label = UILabel()
		label.font = View.font
		return label
	}()
	let foreground: UILabel = {
		let label = UILabel()
		label.font = View.font
		return label
	}()

	lazy var link: CADisplayLink = {
		var link = CADisplayLink(target: self, selector: #selector(tick))
		link.preferredFramesPerSecond = 60
		return link
	}()

	let properties = [
		kCGImagePropertyGIFDictionary: [
			kCGImagePropertyGIFLoopCount: 0, // loop forever
			kCGImagePropertyGIFUnclampedDelayTime: 0.015, // 15 ms between frames; firefox doesn't like anything under 10
			kCGImagePropertyGIFCanvasPixelWidth: View.width,
			kCGImagePropertyGIFCanvasPixelHeight: View.height,
		]
	]
	var destination: CGImageDestination!

	var tickCount = 0

	var word: String! {
		get { background.text }
		set {
			background.text = newValue
			background.sizeToFit()

			foreground.text = newValue
			foreground.sizeToFit()

			// lol
			// break out of the sandbox and save to the actual desktop instead of simulator desktop, at least with iOS 14 sim on Xcode 12.4
			let components = ("~" as NSString).expandingTildeInPath.components(separatedBy: "/")
			let path = "/" + components[1] + "/" + components[2] + "/Desktop/\(newValue!).gif"
			let url = URL(fileURLWithPath: path)
			print(url)
			destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, 37, nil)!
			CGImageDestinationSetProperties(destination, properties as CFDictionary)
		}
	}

	@objc func tick() {
		let backgroundHue = CGFloat(tickCount) % 360.0
		let foregroundHue: CGFloat = {
			let value = backgroundHue - 90.0
			return value > 0 ? value : (90.0 + value)
		}()

		// 231 is an arbitrary offset start offset at the top instead of bottom; varies per word and font
		let radians = CGFloat(tickCount + 231) * .pi / 180
		let cosine = cos(radians)
		let sine = sin(radians)
		let dx = foreground.bounds.size.width * 0.1
		let dy = foreground.bounds.size.height * 0.1

		var point = center
		point.x += (dx * cosine - dy * sine)
		point.y += (dx * sine + dy * cosine)
		foreground.center = point

		background.center = center
		background.textColor = .init(hue: foregroundHue / 360.0, saturation: 0.69, brightness: 1.0, alpha: 1.0)
		foreground.textColor = .init(hue: backgroundHue / 360.0, saturation: 0.69, brightness: 1.0, alpha: 1.0)

		let snapshot = snapshotView(afterScreenUpdates: true)
		let frame = UIGraphicsImageRenderer(size: bounds.size, format: .init(for: .init(displayScale: 1.0))).image { context in
			snapshot?.drawHierarchy(in: .init(origin: .zero, size: bounds.size), afterScreenUpdates: true)
		}

		CGImageDestinationAddImage(destination, frame.cgImage!, properties as CFDictionary)

		if tickCount == 360 {
			link.invalidate()

			let final = CGImageDestinationFinalize(destination)
			print("saved? \(final)")

			return
		}

		tickCount = tickCount + 10 // ideally this would be + 5 and inter-frameduration would be 1/2 current value, but ImageIO doesn't seem to want to make that animate fast
	}

	override func willMove(toWindow newWindow: UIWindow?) {
		if newWindow != nil {
			addSubview(background)
			addSubview(foreground)
			link.add(to: .current, forMode: .common)
		}
	}
}

class ViewController: UIViewController {
	override var prefersStatusBarHidden: Bool { true }
	override func viewDidLoad() {
		super.viewDidLoad()

		let v = View(frame: .init(origin: .zero, size: .init(width: View.width, height: View.height)))
		v.word = "lol"

		view.addSubview(v)
	}
}
