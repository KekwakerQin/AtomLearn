import UIKit

final class AddCardsViewController: UIViewController {
    
    // MARK: - Tabs

    private enum Tab {
        case manual
        case ai
        case importSource
    }

    private enum SlideDirection {
        case left   // new view comes from right, old goes to left (swipe left / next)
        case right  // new view comes from left, old goes to right (swipe right / prev)
    }

    private var currentTab: Tab = .manual
    private weak var currentChild: UIViewController?
    
    // MARK: - Interactive swipe state

    private var isInteracting: Bool = false
    private var interactiveFromTab: Tab?
    private var interactiveToTab: Tab?
    private var interactiveDirection: SlideDirection?
    private weak var interactiveCurrentVC: UIViewController?
    private weak var interactiveNextVC: UIViewController?
    
    // MARK: - Dependencies
    private let viewModel: AddCardsViewModel
    private let makeManualVC: () -> UIViewController
    private let makeAIVC: () -> UIViewController
    private let makeImportVC: () -> UIViewController
    
    // MARK: - UI

    private let tabsStack = UIStackView()
    private let container = UIView()

    private let btnManual = UIButton(type: .system)
    private let btnAI = UIButton(type: .system)
    private let btnImport = UIButton(type: .system)

    private lazy var tabsPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTabsPan(_:)))

    // MARK: - Init
    init(
        viewModel: AddCardsViewModel,
        makeManualVC: @escaping () -> UIViewController,
        makeAIVC: @escaping () -> UIViewController,
        makeImportVC: @escaping () -> UIViewController
    ) {
        self.viewModel = viewModel
        self.makeManualVC = makeManualVC
        self.makeAIVC = makeAIVC
        self.makeImportVC = makeImportVC
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
        
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Добавить карточки"
        setupTabs()
        setupContainer()
        switchTo(.manual)
        setupGestures()
        viewModel.onViewDidLoad()

//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            title: "Добавить",
//            style: .done,
//            target: self,
//            action: #selector(addTapped)
//        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
    }
    
    @objc private func addTapped() {
        viewModel.addCard()
    }
    
    // MARK: - Setup

    private func setupTabs() {
        configureTabButton(btnManual, title: "Вручную", tag: 0)
        configureTabButton(btnAI, title: "AI", tag: 1)
        configureTabButton(btnImport, title: "Документ / Сайт", tag: 2)

        tabsStack.axis = .horizontal
        tabsStack.alignment = .center
        tabsStack.distribution = .fillProportionally
        tabsStack.spacing = 10
        tabsStack.translatesAutoresizingMaskIntoConstraints = false

        tabsStack.addArrangedSubview(btnManual)
        tabsStack.addArrangedSubview(btnAI)
        tabsStack.addArrangedSubview(btnImport)

        view.addSubview(tabsStack)

        NSLayoutConstraint.activate([
            tabsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tabsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tabsStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            tabsStack.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func setupContainer() {
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: tabsStack.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupGestures() {
        tabsPanGesture.delegate = self
        container.addGestureRecognizer(tabsPanGesture)

        // Keep system edge-swipe back.
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func configureTabButton(_ button: UIButton, title: String, tag: Int) {
        button.tag = tag

        var config = UIButton.Configuration.plain()
        config.title = title
        config.titleAlignment = .center
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 14, weight: .semibold)
            return out
        }

        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

        // "Liquid glass": blurred material background in a capsule shape.
        config.background.cornerRadius = 16
        config.background.visualEffect = UIBlurEffect(style: .systemThinMaterial)
        config.background.backgroundColor = .clear

        config.baseForegroundColor = .secondaryLabel

        button.configuration = config

        // Let the system keep the look in sync with selection/highlight.
        button.configurationUpdateHandler = { [weak self] b in
            guard let self else { return }
            self.updateGlassAppearance(for: b)
        }

        button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
    }
    
    private func updateGlassAppearance(for button: UIButton) {
        guard var config = button.configuration else { return }

        // Selected tab: stronger material + primary text.
        if button.isSelected {
            config.baseForegroundColor = .label
            config.background.visualEffect = UIBlurEffect(style: .systemMaterial)
            config.background.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        } else {
            config.baseForegroundColor = .secondaryLabel
            config.background.visualEffect = UIBlurEffect(style: .systemThinMaterial)
            config.background.backgroundColor = .clear
        }

        button.configuration = config
    }
    
    // MARK: - Tabs logic

    private var orderedTabs: [Tab] { [.manual, .ai, .importSource] }

    private func tabIndex(_ tab: Tab) -> Int {
        orderedTabs.firstIndex(of: tab) ?? 0
    }

    private func tab(at index: Int) -> Tab {
        orderedTabs[max(0, min(index, orderedTabs.count - 1))]
    }

    private func switchToNextTab() {
        let next = tab(at: tabIndex(currentTab) + 1)
        guard next != currentTab else { return }
        switchTo(next, animated: true, direction: .left)
    }

    private func switchToPreviousTab() {
        let prev = tab(at: tabIndex(currentTab) - 1)
        guard prev != currentTab else { return }
        switchTo(prev, animated: true, direction: .right)
    }

    @objc private func handleTabsPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: container)
        let velocity = gesture.velocity(in: container)

        // Prefer horizontal intent.
        guard abs(velocity.x) > abs(velocity.y) else { return }

        let width = max(container.bounds.width, 1)
        let dx = translation.x

        switch gesture.state {
        case .began:
            guard !isInteracting else { return }
            guard let current = currentChild else { return }

            // Determine direction from initial velocity.
            let direction: SlideDirection = (velocity.x < 0) ? .left : .right

            // Determine target tab.
            let fromTab = currentTab
            let target: Tab
            if direction == .left {
                target = tab(at: tabIndex(fromTab) + 1)
            } else {
                target = tab(at: tabIndex(fromTab) - 1)
            }

            // If we're at the edge (no next/prev), do nothing.
            guard target != fromTab else { return }

            // Prepare next VC.
            let next: UIViewController
            switch target {
            case .manual: next = manualVC
            case .ai: next = aiVC
            case .importSource: next = importVC
            }

            // Mark interaction state.
            isInteracting = true
            interactiveFromTab = fromTab
            interactiveToTab = target
            interactiveDirection = direction
            interactiveCurrentVC = current
            interactiveNextVC = next

            // Preselect tab (so the top bar reflects the target during drag).
            setActive(target)

            // Ensure layout is up-to-date.
            container.layoutIfNeeded()

            // Add next view offscreen.
            if next.parent == nil {
                addChild(next)
            }

            let offset = (direction == .left) ? width : -width
            next.view.frame = container.bounds.offsetBy(dx: offset, dy: 0)
            next.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if next.view.superview == nil {
                container.addSubview(next.view)
            } else {
                container.bringSubviewToFront(next.view)
            }

        case .changed:
            guard isInteracting,
                  let current = interactiveCurrentVC,
                  let next = interactiveNextVC,
                  let direction = interactiveDirection
            else { return }

            // Clamp dx to one screen width AND block dragging opposite to the chosen direction.
            let directionalDx: CGFloat
            if direction == .left {
                // Only allow dragging left (dx <= 0)
                directionalDx = min(0, dx)
            } else {
                // Only allow dragging right (dx >= 0)
                directionalDx = max(0, dx)
            }

            let clampedDx = max(-width, min(directionalDx, width))

            if direction == .left {
                // Finger moves left (dx negative): current follows dx, next comes from right.
                current.view.frame = container.bounds.offsetBy(dx: clampedDx, dy: 0)
                next.view.frame = container.bounds.offsetBy(dx: width + clampedDx, dy: 0)
            } else {
                // Finger moves right (dx positive): current follows dx, next comes from left.
                current.view.frame = container.bounds.offsetBy(dx: clampedDx, dy: 0)
                next.view.frame = container.bounds.offsetBy(dx: -width + clampedDx, dy: 0)
            }

        case .ended, .cancelled, .failed:
            guard isInteracting,
                  let fromTab = interactiveFromTab,
                  let toTab = interactiveToTab,
                  let current = interactiveCurrentVC,
                  let next = interactiveNextVC,
                  let direction = interactiveDirection
            else {
                resetInteractiveState()
                return
            }

            let directionalDx: CGFloat = (direction == .left) ? min(0, dx) : max(0, dx)
            let progress = min(1, max(0, abs(directionalDx) / width))
            let shouldFinishByProgress = progress > 0.33
            let shouldFinishByVelocity: Bool = {
                guard abs(velocity.x) > 650 else { return false }
                if direction == .left { return velocity.x < 0 }
                else { return velocity.x > 0 }
            }()
            let shouldFinish = (gesture.state == .ended) && (shouldFinishByProgress || shouldFinishByVelocity)

            let duration: TimeInterval = 0.22

            if shouldFinish {
                let finalOffset = (direction == .left) ? -width : width
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                    current.view.frame = self.container.bounds.offsetBy(dx: finalOffset, dy: 0)
                    next.view.frame = self.container.bounds
                } completion: { _ in
                    // Remove old
                    current.willMove(toParent: nil)
                    current.view.removeFromSuperview()
                    current.removeFromParent()

                    // Finalize next
                    if next.parent == nil { self.addChild(next) } // safety
                    next.didMove(toParent: self)

                    self.currentChild = next
                    self.currentTab = toTab

                    self.resetInteractiveState()
                }
            } else {
                // Cancel: animate back to original positions and remove next.
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                    current.view.frame = self.container.bounds
                    let offset = (direction == .left) ? width : -width
                    next.view.frame = self.container.bounds.offsetBy(dx: offset, dy: 0)
                } completion: { _ in
                    // Restore top bar selection.
                    self.setActive(fromTab)

                    // Remove next view if it was temporarily added.
                    next.view.removeFromSuperview()
                    next.willMove(toParent: nil)
                    if next.parent === self {
                        next.removeFromParent()
                    }

                    self.resetInteractiveState()
                }
            }

        default:
            break
        }
    }
    
    private func resetInteractiveState() {
        isInteracting = false
        interactiveFromTab = nil
        interactiveToTab = nil
        interactiveDirection = nil
        interactiveCurrentVC = nil
        interactiveNextVC = nil
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let target: Tab
        switch sender.tag {
        case 0: target = .manual
        case 1: target = .ai
        default: target = .importSource
        }

        guard target != currentTab else { return }

        let from = tabIndex(currentTab)
        let to = tabIndex(target)
        let direction: SlideDirection = (to > from) ? .left : .right

        switchTo(target, animated: true, direction: direction)
    }

    private func setActive(_ tab: Tab) {
        let buttons = [btnManual, btnAI, btnImport]
        buttons.forEach { $0.isSelected = false }

        switch tab {
        case .manual: btnManual.isSelected = true
        case .ai: btnAI.isSelected = true
        case .importSource: btnImport.isSelected = true
        }

        // Trigger configurationUpdateHandler to refresh the glass look.
        buttons.forEach { $0.setNeedsUpdateConfiguration() }
    }
    
    // MARK: - Child ViewControllers

    private lazy var manualVC: UIViewController = makeManualVC()
    private lazy var aiVC: UIViewController = makeAIVC()
    private lazy var importVC: UIViewController = makeImportVC()

    private func switchTo(_ tab: Tab, animated: Bool, direction: SlideDirection) {
        currentTab = tab
        setActive(tab)

        let vc: UIViewController
        switch tab {
        case .manual: vc = manualVC
        case .ai: vc = aiVC
        case .importSource: vc = importVC
        }

        if animated {
            slideEmbed(vc, direction: direction)
        } else {
            embed(vc)
        }
    }

    private func switchTo(_ tab: Tab) {
        // initial / non-animated switch
        switchTo(tab, animated: false, direction: .left)
    }

    private func embed(_ child: UIViewController) {
        // Remove current embedded child (only the one inside container)
        if let current = currentChild {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        addChild(child)
        child.view.frame = container.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(child.view)
        child.didMove(toParent: self)

        currentChild = child
    }

    private func slideEmbed(_ next: UIViewController, direction: SlideDirection) {
        // If nothing embedded yet, just embed without animation.
        guard let current = currentChild else {
            embed(next)
            return
        }
        guard current !== next else { return }

        addChild(next)

        let width = container.bounds.width
        let offset = (direction == .left) ? width : -width

        // Start next view offscreen.
        next.view.frame = container.bounds.offsetBy(dx: offset, dy: 0)
        next.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(next.view)

        // Animate both: current out, next in.
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            current.view.frame = current.view.frame.offsetBy(dx: -offset, dy: 0)
            next.view.frame = self.container.bounds
        } completion: { _ in
            // Cleanup current
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()

            // Finalize next
            next.didMove(toParent: self)
            self.currentChild = next
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
        viewModel.cancel()
    }
}

extension AddCardsViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // System interactive pop should work only when there is something to pop.
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            return (navigationController?.viewControllers.count ?? 0) > 1
        }

        if gestureRecognizer === tabsPanGesture {
            let location = gestureRecognizer.location(in: container)

            // If the pan starts near the left edge, prefer the system back swipe.
            let leftEdgeZone: CGFloat = 24
            if location.x <= leftEdgeZone {
                return false
            }

            // Only begin for horizontal pans.
            let pan = gestureRecognizer as! UIPanGestureRecognizer
            let v = pan.velocity(in: container)
            return abs(v.x) > abs(v.y)
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Avoid conflicts between our tab pan and the system back gesture.
        if (gestureRecognizer === tabsPanGesture && otherGestureRecognizer == navigationController?.interactivePopGestureRecognizer) ||
            (otherGestureRecognizer === tabsPanGesture && gestureRecognizer == navigationController?.interactivePopGestureRecognizer) {
            return false
        }
        return false
    }
}
