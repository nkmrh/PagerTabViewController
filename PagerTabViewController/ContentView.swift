import UIKit

final class PagerTabViewController: UIViewController {

    private weak var pageScrollView: UIScrollView?
    private var selectedIndex = 0
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?

    // スワイプ開始時に記録する基準値
    private var dragStartOffsetX: CGFloat = 0
    private var dragStartIndex: Int = 0

    // タブタップによるプログラム遷移中かどうか
    private var isProgrammaticTransition = false

    var viewControllers: [UIViewController] = [] {
        didSet {
            // タブを作り直す
            tabStackView.arrangedSubviews.forEach { view in
                tabStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            for vc in viewControllers {
                let tabButton = UIButton(type: .system)
                tabButton.setTitle(vc.title, for: .normal)
                tabButton.addTarget(self, action: #selector(handleTabButtonTapped(_:)), for: .touchUpInside)
                tabStackView.addArrangedSubview(tabButton)
            }

            // 最初のページ
            if let firstVC = viewControllers.first {
                pageVC.setViewControllers([firstVC], direction: .forward, animated: false)
                selectedIndex = 0

                Task { [weak self] in
                    self?.snapIndicator(to: 0, animated: false)
                }
            }
        }
    }

    private lazy var tabScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .green
        return scrollView
    }()

    private lazy var tabStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        return view
    }()

    private lazy var pageVC: UIPageViewController = {
        let vc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        vc.dataSource = self
        vc.delegate = self
        return vc
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // タブバー
        view.addSubview(tabScrollView)
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            tabScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 44),
        ])

        tabScrollView.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.trailingAnchor),
            tabStackView.bottomAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.bottomAnchor),
            tabStackView.heightAnchor.constraint(equalTo: tabScrollView.frameLayoutGuide.heightAnchor),
            tabStackView.widthAnchor.constraint(greaterThanOrEqualTo: tabScrollView.frameLayoutGuide.widthAnchor),
        ])

        // インジケータ
        tabScrollView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: tabStackView.leadingAnchor)
        indicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            indicatorView.bottomAnchor.constraint(equalTo: tabStackView.bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 4),
            indicatorLeadingConstraint!,
            indicatorWidthConstraint!,
        ])

        // Page VC
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: tabScrollView.bottomAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        pageScrollView = pageVC.view.subviews.compactMap { $0 as? UIScrollView }.first
        pageScrollView?.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        snapIndicator(to: selectedIndex, animated: false)
    }

    // MARK: - Actions

    @objc private func handleTabButtonTapped(_ sender: UIButton) {
        guard let nextIndex = tabStackView.arrangedSubviews.firstIndex(of: sender),
              let currentVC = pageVC.viewControllers?.first,
              let currentIndex = viewControllers.firstIndex(of: currentVC),
              nextIndex != currentIndex else { return }

        isProgrammaticTransition = true
        selectedIndex = nextIndex

        pageVC.setViewControllers(
            [viewControllers[nextIndex]],
            direction: nextIndex > currentIndex ? .forward : .reverse,
            animated: true
        )

        snapIndicator(to: nextIndex, animated: true)
    }

    // MARK: - Indicator

    private func snapIndicator(to index: Int, animated: Bool) {
        guard index < tabStackView.arrangedSubviews.count else { return }

        tabScrollView.layoutIfNeeded()
        tabStackView.layoutIfNeeded()

        let tab = tabStackView.arrangedSubviews[index]
        indicatorLeadingConstraint?.constant = tab.frame.minX
        indicatorWidthConstraint?.constant = tab.frame.width

        let apply = { self.tabScrollView.layoutIfNeeded() }

        if animated {
            UIView.animate(withDuration: 0.22,
                           delay: 0,
                           options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                           animations: apply)
        } else {
            apply()
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension PagerTabViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return viewControllers[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index < viewControllers.count - 1 else { return nil }
        return viewControllers[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension PagerTabViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pvc: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        defer { isProgrammaticTransition = false }

        if completed,
           let current = pvc.viewControllers?.first,
           let idx = viewControllers.firstIndex(of: current) {

            selectedIndex = idx
            if !isProgrammaticTransition {
                snapIndicator(to: idx, animated: false)
            }
        } else {
            if !isProgrammaticTransition {
                snapIndicator(to: selectedIndex, animated: false)
            }
        }
    }
}

// MARK: - UIScrollViewDelegate（スワイプ中だけ追従）

extension PagerTabViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let pageScrollView = pageScrollView,
              scrollView === pageScrollView else { return }

        dragStartOffsetX = scrollView.contentOffset.x
        dragStartIndex = selectedIndex
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isProgrammaticTransition { return }

        guard let pageScrollView = pageScrollView,
              scrollView === pageScrollView,
              tabStackView.arrangedSubviews.count == viewControllers.count,
              scrollView.bounds.width > 0 else { return }

        let width = scrollView.bounds.width

        // ★ スワイプ開始からの差分を進行度とする
        let rawProgress = (scrollView.contentOffset.x - dragStartOffsetX) / width

        if abs(rawProgress) < 0.001 { return }

        let from = dragStartIndex
        let to = rawProgress > 0
            ? min(from + 1, viewControllers.count - 1)
            : max(from - 1, 0)

        if to == from { return }

        let t = max(0, min(1, abs(rawProgress)))

        tabScrollView.layoutIfNeeded()
        tabStackView.layoutIfNeeded()

        let fromTab = tabStackView.arrangedSubviews[from]
        let toTab = tabStackView.arrangedSubviews[to]

        indicatorLeadingConstraint?.constant =
            fromTab.frame.minX + (toTab.frame.minX - fromTab.frame.minX) * t

        indicatorWidthConstraint?.constant =
            fromTab.frame.width + (toTab.frame.width - fromTab.frame.width) * t

        UIView.performWithoutAnimation {
            tabScrollView.layoutIfNeeded()
        }
    }
}

// MARK: - Preview

import SwiftUI

struct PagerTabViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let pagerTabVC = PagerTabViewController()
        pagerTabVC.viewControllers = (0..<3).map { i in
            let vc = UIViewController()
            vc.title = "Tab(\(i))"
            vc.view.backgroundColor = generateRandomColor()
            return vc
        }
        return pagerTabVC
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

private func generateRandomColor() -> UIColor {
    let r = CGFloat.random(in: 0 ... 255) / 255.0
    let g = CGFloat.random(in: 0 ... 255) / 255.0
    let b = CGFloat.random(in: 0 ... 255) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: 1.0)
}

#Preview {
    PagerTabViewControllerPreview()
}
