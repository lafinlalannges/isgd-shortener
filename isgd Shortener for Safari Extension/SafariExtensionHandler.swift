//
//  SafariExtensionHandler.swift
//  isgd Shortener for Safari Extension
//
//  Created by Lafin Lalannges on 2025/12/24.
//

import SafariServices
import os.log

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    // MARK: - 記錄日誌（方便除錯）
    private let logger = Logger(subsystem: "isgd.shortener", category: "SafariExtension")
    
    override func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }
        logger.info("Extension received request for profile: \(profile?.uuidString ?? "none")")
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
            self.logger.info("Message received: \(messageName) from page: \(String(describing: properties?.url)), userInfo: \(userInfo ?? [:])")
        }
    }
    
    // MARK: - 工具列按鈕被點擊：核心邏輯
    override func toolbarItemClicked(in window: SFSafariWindow) {
        logger.info("Toolbar item clicked - starting URL shortening...")
        
        // 步驟 1：抓當前 window 的第一個 tab 的 URL
        window.getActiveTab { tab in
            guard let tab = tab else {
                self.showError("找不到當前分頁")
                return
            }
            
            tab.getActivePage { page in
                guard let page = page else {
                    self.showError("找不到當前頁面")
                    return
                }
                
                page.getPropertiesWithCompletionHandler { properties in
                    guard let url = properties?.url else {
                        self.showError("無法取得頁面網址")
                        return
                    }
                    let urlString = url.absoluteString
                    guard !urlString.isEmpty else {
                        self.showError("無法取得頁面網址")
                        return
                    }
                    
                    // 步驟 2：呼叫 is.gd API 縮址
                    self.shortenURL(longURL: urlString) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let shortURL):
                                // 步驟 3：複製到剪貼簿
                                self.copyToClipboard(shortURL)
                                // 步驟 4：更新 popover 顯示結果
                                SafariExtensionViewController.shared.update(
                                    with: shortURL,
                                    status: "✅ 已複製到剪貼簿"
                                )
                                self.logger.info("Short URL generated: \(shortURL)")
                                
                            case .failure(let error):
                                self.showError("縮址失敗：\(error.localizedDescription)")
                                self.logger.error("Shortening failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        
        // 步驟 5：顯示 popover（如果還沒顯示的話）
        window.getToolbarItem { toolbarItem in
            toolbarItem?.showPopover()
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping (Bool, String) -> Void) {
        validationHandler(true, "") // 永遠啟用
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        SafariExtensionViewController.shared
    }
    override func popoverWillShow(in window: SFSafariWindow) {
        window.getActiveTab { tab in
            guard let tab = tab else {
                self.showError("找不到當前分頁")
                return
            }
            
            tab.getActivePage { page in
                guard let page = page else {
                    self.showError("找不到當前頁面")
                    return
                }

                page.getPropertiesWithCompletionHandler { properties in
                    guard let url = properties?.url else {
                        self.logger.error("Unable to get page URL in popoverWillShow")
                        self.showError("無法取得頁面網址")
                        return
                    }
                    // 增加 log以記錄
                    self.logger.info("Active page URL: \(url.absoluteString)")

                    let urlString = url.absoluteString
                    self.shortenURL(longURL: urlString) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let shortURL):
                                self.copyToClipboard(shortURL)
                                SafariExtensionViewController.shared.update(
                                    with: shortURL,
                                    status: "✅ 已複製到剪貼簿"
                                )
                            case .failure(let error):
                                self.showError("縮址失敗：\(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }

    
    // MARK: - is.gd API 呼叫（跟主 App 共用邏輯）
    private func shortenURL(longURL: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://is.gd/create.php?format=simple&url=\(longURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }
        
        logger.info("Calling is.gd API for: \(longURL)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let shortURL = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !shortURL.isEmpty,
                  !shortURL.hasPrefix("Error") else {
                completion(.failure(NSError(domain: "APIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "is.gd API 回傳錯誤"])))
                return
            }
            
            completion(.success(shortURL))
        }
        task.resume()
    }
    
    // MARK: - 複製到 macOS 剪貼簿
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        logger.info("Copied to clipboard: \(text)")
    }
    
    // MARK: - 在 popover 顯示錯誤訊息
    private func showError(_ message: String) {
        SafariExtensionViewController.shared.update(
            with: "❌ 錯誤",
            status: message
        )
    }
}

