import UIKit

// 角丸＋パディングの簡易ラベル
private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) { self.insets = insets; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return .init(width: s.width + insets.left + insets.right,
                     height: s.height + insets.top + insets.bottom)
    }
}

final class BadgeButton: UIControl {
    private let title = UILabel()
    private let badge = PaddingLabel(insets: .init(top: 2, left: 6, bottom: 2, right: 6))
    private let hstack = UIStackView()

    var badgeText: String? { didSet { updateBadge() } }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // タイトル
        title.font = .systemFont(ofSize: 16, weight: .medium)
        title.textColor = .white
        title.setContentCompressionResistancePriority(.required, for: .horizontal)

        // バッジ
        badge.backgroundColor = .systemRed
        badge.textColor = .white
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.isHidden = true
        badge.clipsToBounds = true
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        // 横並び
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 6
        hstack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hstack)
        hstack.addArrangedSubview(title)
        hstack.addArrangedSubview(badge)

        hstack.isUserInteractionEnabled = false
        title.isUserInteractionEnabled = false

        // 中央配置＋左右に少し余白（テキスト＋バッジ全体が真ん中に来る）
        NSLayoutConstraint.activate([
            hstack.centerXAnchor.constraint(equalTo: centerXAnchor),
            hstack.centerYAnchor.constraint(equalTo: centerYAnchor),
            hstack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            hstack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
            badge.widthAnchor.constraint(greaterThanOrEqualTo: badge.heightAnchor)
        ])
        clipsToBounds = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet {
            title.alpha = isHighlighted ? 0.6 : 1.0
            badge.alpha = isHighlighted ? 0.85 : 1.0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        badge.layer.cornerRadius = badge.bounds.height / 2
    }

    // 公開：タイトル設定（UIButton互換っぽく）
    func setTitle(_ text: String?) {
        title.text = text
        setNeedsLayout()
    }

    private func updateBadge() {
        if let t = badgeText, !t.isEmpty {
            badge.text = t
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }
        setNeedsLayout()
    }
}
