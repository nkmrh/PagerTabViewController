import UIKit
import SwiftUI

final class PagerTabViewController: UIViewController, UIScrollViewDelegate {

    // MARK: Public
    var viewControllers: [UIViewController] = [] {
        didSet { rebuildTabsAndPages() }
    }

    // MARK: UI (Tab)
    private static let tabBarHeight: CGFloat = 44
    private let tabBarScrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsHorizontalScrollIndicator = false
        v.backgroundColor = .blue
        return v
    }()
    private let tabBarStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually   // 収まると等幅／はみ出たらスクロール
        v.alignment = .fill
        v.spacing = 0
        return v
    }()
    private let indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()
    private var indicatorLeading: NSLayoutConstraint?
    private var indicatorWidth: NSLayoutConstraint?

    // MARK: UI (Content) - StackViewは使わない
    private let contentScrollView: UIScrollView = {
        let v = UIScrollView()
        v.isPagingEnabled = true
        v.bounces = true
        v.alwaysBounceHorizontal = true
        v.showsHorizontalScrollIndicator = false
        v.showsVerticalScrollIndicator = false
        v.isDirectionalLockEnabled = true
        return v
    }()

    // 保持用
    private var pageContainers: [UIView] = []

    // MARK: State
    private var selectedIndex: Int = 0

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // --- Tab bar layout ---
        view.addSubview(tabBarScrollView)
        tabBarScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBarScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            tabBarScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarScrollView.heightAnchor.constraint(equalToConstant: Self.tabBarHeight),
        ])

        tabBarScrollView.addSubview(tabBarStackView)
        tabBarStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBarStackView.topAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.topAnchor),
            tabBarStackView.leadingAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.leadingAnchor),
            tabBarStackView.trailingAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.trailingAnchor),
            tabBarStackView.bottomAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.bottomAnchor),
            tabBarStackView.heightAnchor.constraint(equalTo: tabBarScrollView.frameLayoutGuide.heightAnchor),
            tabBarStackView.widthAnchor.constraint(greaterThanOrEqualTo: tabBarScrollView.frameLayoutGuide.widthAnchor)
        ])

        tabBarStackView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorLeading = indicatorView.leadingAnchor.constraint(equalTo: tabBarStackView.leadingAnchor)
        indicatorWidth = indicatorView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
            indicatorView.bottomAnchor.constraint(equalTo: tabBarStackView.bottomAnchor),
            indicatorLeading!, indicatorWidth!
        ])

        // --- Content layout (no stack view) ---
        view.addSubview(contentScrollView)
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: tabBarScrollView.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        contentScrollView.delegate = self
    }

    // MARK: Build
    private func rebuildTabsAndPages() {
        // Tabs
        tabBarStackView.arrangedSubviews.forEach { v in
            tabBarStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for (i, vc) in viewControllers.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(vc.title ?? "Tab \(i+1)", for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            b.setTitleColor(.white, for: .normal)
            b.backgroundColor = .green
            b.tag = i
            b.addTarget(self, action: #selector(didTapTab(_:)), for: .touchUpInside)
            tabBarStackView.addArrangedSubview(b)
        }

        // Pages (NO UIStackView)
        // 既存子VC/ページビューを除去
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        pageContainers.forEach { $0.removeFromSuperview() }
        pageContainers.removeAll()

        var previousTrailing: NSLayoutXAxisAnchor? = nil

        for vc in viewControllers {
            addChild(vc)

            // 各ページのコンテナ（AutoLayout用）
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            contentScrollView.addSubview(container)
            pageContainers.append(container)

            // コンテナの制約：高さ=フレーム高さ、幅=フレーム幅（1ページ=画面幅）
            var constraints: [NSLayoutConstraint] = [
                container.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor),
                container.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor),
                container.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
                container.heightAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.heightAnchor)
            ]
            if let prev = previousTrailing {
                constraints.append(container.leadingAnchor.constraint(equalTo: prev))
            } else {
                constraints.append(container.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor))
            }
            NSLayoutConstraint.activate(constraints)
            previousTrailing = container.trailingAnchor

            // 子VCの view を端までフィット
            let v = vc.view!
            v.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(v)
            NSLayoutConstraint.activate([
                v.topAnchor.constraint(equalTo: container.topAnchor),
                v.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                v.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                v.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            vc.didMove(toParent: self)
        }

        // 最後のページで contentLayoutGuide.trailing を閉じる
        if let lastTrailing = previousTrailing {
            lastTrailing.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor).isActive = true
        } else {
            // ページが0枚のときの幅/高さゼロ問題を避ける軽い対策
            contentScrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor).isActive = true
            contentScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor).isActive = true
        }

        // レイアウト反映
        view.layoutIfNeeded()
        setPage(index: min(selectedIndex, max(0, viewControllers.count - 1)), animated: false)
        snapIndicatorToSelected()
    }

    // MARK: Tab tap -> Scroll content
    @objc private func didTapTab(_ sender: UIButton) {
        setPage(index: sender.tag, animated: true)
    }

    private func setPage(index: Int, animated: Bool) {
        selectedIndex = index
        let x = CGFloat(index) * contentScrollView.bounds.width
        contentScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        if !animated { snapIndicatorToSelected() }
        scrollSelectedTabIntoView(animated: animated)
    }

    private func scrollSelectedTabIntoView(animated: Bool) {
        guard selectedIndex < tabBarStackView.arrangedSubviews.count else { return }
        let selected = tabBarStackView.arrangedSubviews[selectedIndex]
        let frame = selected.convert(selected.bounds, to: tabBarScrollView)
        let targetX = max(0, frame.midX - tabBarScrollView.bounds.width / 2)
        let maxX = max(0, tabBarScrollView.contentSize.width - tabBarScrollView.bounds.width)
        tabBarScrollView.setContentOffset(CGPoint(x: min(targetX, maxX), y: 0), animated: animated)
    }

    // MARK: Indicator follow (interactive)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === contentScrollView,
              contentScrollView.bounds.width > 0,
              tabBarStackView.arrangedSubviews.count == viewControllers.count else { return }

        let pageFloat = max(0, contentScrollView.contentOffset.x / contentScrollView.bounds.width)
        let left = Int(floor(pageFloat))
        let progress = pageFloat - CGFloat(left)

        let fromIdx = min(left, tabBarStackView.arrangedSubviews.count - 1)
        let toIdx = min(fromIdx + 1, tabBarStackView.arrangedSubviews.count - 1)
        let fromTab = tabBarStackView.arrangedSubviews[fromIdx]
        let toTab = tabBarStackView.arrangedSubviews[toIdx]

        let fromX = fromTab.frame.minX, toX = toTab.frame.minX
        let fromW = fromTab.frame.width, toW = toTab.frame.width

        indicatorLeading?.constant = fromX + (toX - fromX) * progress
        indicatorWidth?.constant  = fromW + (toW - fromW) * progress
        tabBarStackView.layoutIfNeeded()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { syncSelectedIndexAndCenterTab() }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { syncSelectedIndexAndCenterTab() }

    private func syncSelectedIndexAndCenterTab() {
        let page = Int(round(contentScrollView.contentOffset.x / max(1, contentScrollView.bounds.width)))
        selectedIndex = max(0, min(page, viewControllers.count - 1))
        scrollSelectedTabIntoView(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 回転などで幅が変わったら現在ページに再スナップ
        let x = CGFloat(selectedIndex) * contentScrollView.bounds.width
        contentScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        snapIndicatorToSelected()
    }

    private func snapIndicatorToSelected() {
        guard selectedIndex < tabBarStackView.arrangedSubviews.count else { return }
        let tab = tabBarStackView.arrangedSubviews[selectedIndex]
        indicatorLeading?.constant = tab.frame.minX
        indicatorWidth?.constant = tab.frame.width
        tabBarStackView.layoutIfNeeded()
    }
}

// ==== SwiftUI Preview ====

struct PreviewWrapperViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let pager = PagerTabViewController()
        pager.viewControllers = (0..<20).map { _ in
            let vc = UIViewController();
            vc.view.backgroundColor = .systemRed
            return vc
        }
        return pager
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct ContentView: View {
    var body: some View { PreviewWrapperViewController() }
}

#Preview { ContentView() }
