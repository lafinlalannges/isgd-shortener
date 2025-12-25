//
//  SafariExtensionViewController.swift
//  isgd Shortener for Safari Extension
//
//  Created by Lafin Lalannges on 2025/12/24.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    // MARK: - 單例（SafariExtensionHandler 會透過這抓到我們）
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 340, height: 280)  // 稍微放大一點放按鈕
        return shared
    }()
    
    // MARK: - UI 元件
    private let shortURLLabel = NSTextField()
    private let statusLabel = NSTextField()
    private let mailButton = NSButton()
    private let shareButton = NSButton()
    
    // 指定用這個 init（不用 xib）
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 初始化 UI（短網址顯示 + 狀態 + 兩個按鈕）
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 短網址標籤（大字體、可選取）
        shortURLLabel.isEditable = false
        shortURLLabel.isBezeled = false
        shortURLLabel.drawsBackground = false
        shortURLLabel.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .medium)
        shortURLLabel.textColor = NSColor.labelColor
        shortURLLabel.lineBreakMode = .byTruncatingTail
        shortURLLabel.alignment = .center
        view.addSubview(shortURLLabel)
        
        // 狀態標籤（「已複製到剪貼簿」等訊息）
        statusLabel.isEditable = false
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.font = NSFont.systemFont(ofSize: 13)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.alignment = .center
        view.addSubview(statusLabel)
        
        // Mail 按鈕
        mailButton.title = "📧 Mail"
        mailButton.bezelStyle = .rounded
        mailButton.target = self
        mailButton.action = #selector(mailTapped)
        view.addSubview(mailButton)
        
        // 分享按鈕
        shareButton.title = "↗️ 分享"
        shareButton.bezelStyle = .rounded
        shareButton.target = self
        shareButton.action = #selector(shareTapped)
        view.addSubview(shareButton)
        
        // Auto Layout
        shortURLLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        mailButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 短網址在上方，佔大部分空間
            shortURLLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            shortURLLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            shortURLLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            shortURLLabel.heightAnchor.constraint(equalToConstant: 60),
            
            // 狀態在中間
            statusLabel.topAnchor.constraint(equalTo: shortURLLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 兩個按鈕在下方，左右對齊
            mailButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            mailButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            mailButton.widthAnchor.constraint(equalToConstant: 80),
            mailButton.heightAnchor.constraint(equalToConstant: 28),
            
            shareButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            shareButton.widthAnchor.constraint(equalToConstant: 80),
            shareButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // 初始狀態
        showInitialState()
    }
    
    // MARK: - 顯示初始狀態（「點工具列按鈕縮址」）
    private func showInitialState() {
        shortURLLabel.stringValue = "尚未產生短網址"
        statusLabel.stringValue = "點擊工具列按鈕，將自動縮短目前頁面網址"
        shortURLLabel.textColor = .secondaryLabelColor
        mailButton.isEnabled = false
        shareButton.isEnabled = false
    }
    
    // MARK: - 更新短網址結果（由 SafariExtensionHandler 呼叫）
    func update(with shortURL: String, status: String) {
        shortURLLabel.stringValue = shortURL
        statusLabel.stringValue = status
        shortURLLabel.textColor = NSColor.labelColor
        mailButton.isEnabled = true
        shareButton.isEnabled = true
        
        // 自動選取短網址方便複製
        shortURLLabel.selectText(self)
    }
    
    // MARK: - Mail 按鈕動作
    @objc private func mailTapped() {
        if let url = URL(string: shortURLLabel.stringValue) {
            NSWorkspace.shared.open(URL(string: "mailto:?body=\(url.absoluteString)")!)
        }
    }
    
    // MARK: - 分享按鈕動作
    @objc private func shareTapped() {
        if let url = URL(string: shortURLLabel.stringValue) {
            let picker = NSSharingServicePicker(items: [url])
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}

