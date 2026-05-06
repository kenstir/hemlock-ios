import UIKit

final class AlertAction {
    enum Style {
        case `default`
        case cancel
        case destructive
    }

    let title: String
    let style: Style
    let handler: (() -> Void)?

    init(title: String, style: Style = .default, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

final class AttributedAlertController: UIViewController, UITextViewDelegate {

    private let titleText: String?
    private let attributedMessage: NSAttributedString
    private var actions: [AlertAction] = []

    // MARK: Init

    init(title: String?, message: NSAttributedString) {
        self.titleText = title
        self.attributedMessage = message
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public API

    func addAction(_ action: AlertAction) {
        actions.append(action)
    }

    /// Converts an HTML fragment to an attributed string with dynamic type and dark mode support,
    /// or returns nil if the conversion fails.
    static func attributedString(fromHTML html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8),
              let mutable = try? NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) else { return nil }

        let fullRange = NSRange(location: 0, length: mutable.length)

        // The basic HTML parsing gives us a fixed-size black font, so we need to fix it.
        // Enumerate existing attributes and replace fonts with scaled, preferred fonts
        // preserving symbolic traits (bold/italic) where possible.
//        mutable.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
//            // Determine traits from any existing font
//            var traits = UIFontDescriptor.SymbolicTraits()
//            if let f = attrs[.font] as? UIFont {
//                traits = f.fontDescriptor.symbolicTraits
//            }
//
//            // Create a footnote-sized font
//            var desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
//            if let descWithTraits = desc.withSymbolicTraits(traits) {
//                desc = descWithTraits
//            }
//            let resolvedFont = UIFont(descriptor: desc, size: 0)
//            let scaled = UIFontMetrics(forTextStyle: .body).scaledFont(for: resolvedFont)
//
//            // Replace font and foregroundColor in this range
//            mutable.addAttribute(.font, value: scaled, range: range)
//            mutable.addAttribute(.foregroundColor, value: UIColor.label, range: range)
//        }

        // On further examination, it seems all we really have to do is fix the foreground color here
        // because later we set the textView.font to a dynamic type *after* setting the attributedText
        mutable.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            mutable.addAttribute(.foregroundColor, value: UIColor.label, range: range)
        }

        return mutable
    }

    // MARK: UI

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let container = UIView()
        //container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let blur = UIBlurEffect(style: .systemChromeMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.layer.cornerRadius = 14
        blurView.layer.masksToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Title
        if let titleText {
            let titleLabel = UILabel()
            titleLabel.text = titleText
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            stack.addArrangedSubview(titleLabel)
        }

        // Message (UITextView for links)
        let textView = UITextView()
        textView.attributedText = attributedMessage
        textView.font = .preferredFont(forTextStyle: .footnote)
        textView.textAlignment = .center
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        // Ensure link color matches label color
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.label
        ]

        stack.addArrangedSubview(textView)

        // Buttons
        let buttonStack = makeButtonStack()
        stack.addArrangedSubview(buttonStack)

        // Layout
        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
    }

    private func makeButtonStack() -> UIView {
        let isVertical = actions.count > 1

        let stack = UIStackView()
        stack.axis = isVertical ? .vertical : .horizontal
        stack.spacing = 0
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        for action in actions {
            stack.addArrangedSubview(makeSeparator(isVertical: isVertical))
            stack.addArrangedSubview(makeButton(for: action))
        }

        return container
    }

    private func makeSeparator(isVertical: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.separator

        let thickness = 1.0 / UIScreen.main.scale

        if isVertical {
            view.heightAnchor.constraint(equalToConstant: thickness).isActive = true
        } else {
            view.widthAnchor.constraint(equalToConstant: thickness).isActive = true
        }

        return view
    }

    private func makeButton(for action: AlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        //button.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        switch action.style {
        case .default:
            button.setTitleColor(App.theme.accentColor, for: .normal)
            Style.styleButton(asPlain: button)
        case .cancel:
            button.setTitleColor(.label, for: .normal)
        case .destructive:
            button.setTitleColor(.systemRed, for: .normal)
        }

        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) {
                action.handler?()
            }
        }, for: .touchUpInside)

        return button
    }
}
