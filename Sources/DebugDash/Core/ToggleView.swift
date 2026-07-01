import UIKit

/// Floating toggle button for DebugDash server control
internal final class ToggleView: UIView {
    
    // MARK: - Properties
    
    private let button = UIButton(type: .system)
    private var isServerRunning = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Configure container view
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 0.9)
        layer.cornerRadius = 28 // Half of 56pt for circular shape
        layer.borderWidth = 2
        layer.borderColor = UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0).cgColor // #3b82f6
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        // Configure button
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        addSubview(button)
        
        // Button constraints (fill container)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add tap action
        button.addTarget(self, action: #selector(toggleServer), for: .touchUpInside)
        
        // Initial state
        updateState()
    }
    
    // MARK: - Actions
    
    @objc private func toggleServer() {
        if DebugDashManager.shared.isRunning {
            DebugDashManager.shared.stopServer()
        } else {
            DebugDashManager.shared.startServer()
        }
        
        updateState()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - State Updates
    
    func updateState() {
        isServerRunning = DebugDashManager.shared.isRunning
        
        if isServerRunning {
            // Server is running - show "on" state
            if #available(iOS 15.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
                button.setImage(UIImage(systemName: "wifi.circle.fill", withConfiguration: config), for: .normal)
            } else {
                button.setImage(UIImage(systemName: "wifi"), for: .normal)
            }
            backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.9) // #10b981 success green
            layer.borderColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0).cgColor
        } else {
            // Server is stopped - show "off" state
            if #available(iOS 15.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
                button.setImage(UIImage(systemName: "wifi.slash", withConfiguration: config), for: .normal)
            } else {
                button.setImage(UIImage(systemName: "wifi.slash"), for: .normal)
            }
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 0.9) // #1a1a2e
            layer.borderColor = UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0).cgColor // #3b82f6
        }
        
        // Animate the transition
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        }
    }
}
