import UIKit
import SwiftUI

final class PagerTabViewController: UIViewController {

    // MARK: Public
    var viewControllers: [UIViewController] = [] {
        didSet { rebuildTabs() }
    }

    // MARK: Private UI
    private static let tabBarHeight: CGFloat = 44

    private let tabBarScrollView: UIScrollView = {
        let v = UIScrollView()
        v.backgroundColor = .blue
        v.showsHorizontalScrollIndicator = false
        return v
    }()

    private let tabBarStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.alignment = .fill
        v.spacing = 0
        return v
    }()

    private let indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .blue
        return v
    }()

    // MARK: State
    private var selectedIndex: Int = 0
    private var indicatorLeading: NSLayoutConstraint?
    private var indicatorWidth: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

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
            // スクロール内容領域に4辺を張る（中身の幅＝内容幅）
            tabBarStackView.topAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.topAnchor),
            tabBarStackView.leadingAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.leadingAnchor),
            tabBarStackView.trailingAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.trailingAnchor),
            tabBarStackView.bottomAnchor.constraint(equalTo: tabBarScrollView.contentLayoutGuide.bottomAnchor),

            // 高さはフレームの高さに等しい（縦方向に伸びない）
            tabBarStackView.heightAnchor.constraint(equalTo: tabBarScrollView.frameLayoutGuide.heightAnchor),

            // ★キモ：幅は「フレーム幅以上」にして、収まるときは等幅で横いっぱい、収まらないときはスクロール
            tabBarStackView.widthAnchor.constraint(greaterThanOrEqualTo: tabBarScrollView.frameLayoutGuide.widthAnchor)
        ])

        // インジケータは stackView の下辺に追加
        tabBarStackView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorLeading = indicatorView.leadingAnchor.constraint(equalTo: tabBarStackView.leadingAnchor)
        indicatorWidth = indicatorView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            indicatorView.heightAnchor.constraint(equalToConstant: 4),
            indicatorView.bottomAnchor.constraint(equalTo: tabBarStackView.bottomAnchor),
            indicatorLeading!,
            indicatorWidth!
        ])
    }

    private func rebuildTabs() {
        // 既存のタブをクリア
        tabBarStackView.arrangedSubviews.forEach { sub in
            tabBarStackView.removeArrangedSubview(sub)
            sub.removeFromSuperview()
        }

        // 新しいタブを生成
        for (i, vc) in viewControllers.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(vc.title ?? "Tab \(i+1)", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .green
            button.tag = i
            button.addTarget(self, action: #selector(didTapTab(_:)), for: .touchUpInside)

            // ★fillEquallyを効かせるため、余計な sizeToFit は不要
            tabBarStackView.addArrangedSubview(button)
        }

        // レイアウト後にインジケータ位置を更新
        view.layoutIfNeeded()
        updateIndicator(animated: false)
        scrollSelectedIntoView(animated: false)
    }

    @objc private func didTapTab(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateIndicator(animated: true)
        scrollSelectedIntoView(animated: true)

        // ここで pageVC 連動を入れるなら setViewControllers(...) などを呼ぶ
    }

    private func updateIndicator(animated: Bool) {
        guard selectedIndex < tabBarStackView.arrangedSubviews.count else { return }
        let selected = tabBarStackView.arrangedSubviews[selectedIndex]

        // 選択ボタンの相対位置と幅を反映
        let leading = selected.frame.minX
        let width = selected.frame.width

        indicatorLeading?.constant = leading
        indicatorWidth?.constant = width

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                self.tabBarStackView.layoutIfNeeded()
            }
        } else {
            self.tabBarStackView.layoutIfNeeded()
        }
    }

    private func scrollSelectedIntoView(animated: Bool) {
        guard selectedIndex < tabBarStackView.arrangedSubviews.count else { return }
        let selected = tabBarStackView.arrangedSubviews[selectedIndex]

        // 選択タブを中央めがけてスクロール（余白を考慮）
        let selectedFrame = selected.convert(selected.bounds, to: tabBarScrollView)
        let targetX = max(0, selectedFrame.midX - tabBarScrollView.bounds.width / 2)
        tabBarScrollView.setContentOffset(CGPoint(x: min(targetX, tabBarScrollView.contentSize.width - tabBarScrollView.bounds.width), y: 0),
                                          animated: animated)
    }

    // レイアウト変化（回転やサイズ変更）時にも追従
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateIndicator(animated: false)
        scrollSelectedIntoView(animated: false)
    }
}

// ==== SwiftUI Preview ====

struct PreviewWrapperViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let pagerTabVC = PagerTabViewController()
        let vc1 = UIViewController()
        vc1.title = "Home"
        vc1.view.backgroundColor = .darkGray
        let vc2 = UIViewController()
        vc2.title = "Explore"
        vc2.view.backgroundColor = .brown
        let vc3 = UIViewController()
        vc3.title = "Profile"
        vc3.view.backgroundColor = .purple
        pagerTabVC.viewControllers = [vc1, vc2, vc1, vc2, vc1, vc2, vc1, vc2]
        return pagerTabVC
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        PreviewWrapperViewController()
    }
}

#Preview {
    ContentView()
}
