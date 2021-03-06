import UIKit

/// The view-manager of the application. It manages the canvas and the canvas' set of controls.
public class CanvasController: UIView {
	let canvas: Canvas
	let palette: Palette
	let controlCenter: CanvasControlCenter
	let width: Int
	let height: Int
	let pixelSize: CGFloat
	let colors: Array<UIColor>
	let theme: Theme
	let saveURL: URL

	static var numberOfSaves: Int = 0

	var currentPaintBrush: UIColor = .black {
		didSet {
			canvas.paintBrushColor = currentPaintBrush
		}
	}

	public init(width: Int, height: Int, pixelSize: CGFloat, canvasColor: UIColor, colorPalette: [UIColor], theme: Theme, saveURL: URL) {
		self.width = width
		self.height = height
		self.pixelSize = pixelSize
		self.colors = colorPalette.filter{ $0 != canvasColor } + [canvasColor]
		self.saveURL = saveURL

		canvas = Canvas(width: width, height: height, pixelSize: pixelSize, canvasColor: canvasColor)
		palette = Palette(colors: colors, theme: theme)
		controlCenter = CanvasControlCenter(theme: theme)
		self.theme = theme
		super.init(frame: CGRect(
			x: 0,
			y: 0,
			width:  max(controlCenter.bounds.width + palette.bounds.width + Metrics.regular * 4, CGFloat(width) * pixelSize + Metrics.regular * 4),
			height: max(canvas.bounds.height + controlCenter.bounds.height + Metrics.regular * 3, palette.bounds.height + Metrics.regular * 2 )))

		setupViews()
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setupViews() {
		if let startingPaintBrush = self.colors.first {
			currentPaintBrush = startingPaintBrush
		}
		backgroundColor = theme.mainColor

		palette.delegate = self
		controlCenter.delegate = self

		addSubview(canvas)
		addSubview(palette)
		addSubview(controlCenter)

		canvas.frame.origin = CGPoint(x: Metrics.regular, y: Metrics.regular)
		controlCenter.frame.origin = CGPoint(
			x: Metrics.regular,
			y: canvas.bounds.height + Metrics.regular * 2
		)
		palette.frame.origin = CGPoint(
			x: max(CGFloat(width) * pixelSize + 30, controlCenter.bounds.width + Metrics.regular * 2),
			y: Metrics.regular
		)

	}
}

extension CanvasController: PaletteDelegate {
	func paintBrushDidChange(color: UIColor) {
		currentPaintBrush = color
	}
}

extension CanvasController: CanvasControlCenterDelegate {
	func redoPressed() {
		canvas.viewModel.redo()
	}

	func undoPressed() {
		canvas.viewModel.undo()
	}

	func savePressed() {
		let image = canvas.makeImageFromSelf()
		do {
			guard let image = UIImagePNGRepresentation(image) else {
				return print("Couldn't get image from current context")
			}
			try image.write(to: saveURL, options: .atomic)
			print("Save successful!")
		} catch let error {
			print("Error: \(error)")
		}
		
	}
}
