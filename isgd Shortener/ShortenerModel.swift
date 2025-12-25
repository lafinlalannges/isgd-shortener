//
//  ShortenerModel.swift.swift
//  isgd URL Shortener
//
//  Created by Lafin Lalannges on 2025/12/3.
//

import Foundation
import Observation
import AppKit

@available(macOS 14.0, *)
@Observable
class ShortenerModel {
    var inputURL: String = ""
    var shortURL: String = ""
    var statusMessage: String = ""
    var isLoading: Bool = false
    var isError: Bool = false

    // MARK: - 縮短網址
    func shorten() {
        guard !inputURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("請輸入網址", isError: true)
            return
        }

        isLoading = true
        statusMessage = ""
        isError = false

        // 呼叫 is.gd縮址服務
        let encoded = inputURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputURL
        let apiString = "https://is.gd/create.php?format=json&url=\(encoded)"

        // 暫時印出 apiString的輸出結果
        // print("API URL =", apiString)
        
        guard let url = URL(string: apiString) else {
            isLoading = false
            showStatus("無效的網址格式", isError: true)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error {
                    // 暫時印出 Error
                    // print("URLSession error =", error)
                    
                    self.showStatus("錯誤：\(error.localizedDescription)", isError: true)
                    return
                }

                guard let data else {
                    self.showStatus("無法取得回應", isError: true)
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let short = json?["shorturl"] as? String {
                        self.shortURL = short
                        self.copyToClipboard()
                        self.showStatus("✓ 網址已縮短並複製到剪貼簿", isError: false)
                    } else if let errMsg = json?["error"] as? String {
                        self.showStatus("錯誤：\(errMsg)", isError: true)
                    } else {
                        self.showStatus("無法解析回應", isError: true)
                    }
                } catch {
                    self.showStatus("解析錯誤", isError: true)
                }
            }
        }.resume()
    }

    // MARK: - 複製剪貼簿
    func copyToClipboard() {
        guard !shortURL.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(shortURL, forType: .string)
        showStatus("✓ 已複製到剪貼簿", isError: false)
    }

    // MARK: - 分享
    func openInBrowser() {
        guard let url = URL(string: shortURL) else { return }
        NSWorkspace.shared.open(url)
    }

    func shareViaAirDrop() {
        guard !shortURL.isEmpty else { return }
        let items: [Any] = [shortURL]
        if let service = NSSharingService(named: .sendViaAirDrop) {
            service.perform(withItems: items)
        } else {
            showStatus("AirDrop 無法使用", isError: true)
        }
    }

    func shareViaMail() {
        guard !shortURL.isEmpty else { return }
        let subject = "分享一個縮短網址"
        let body = "我想與你分享這個連結:\n\(shortURL)"

        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 狀態訊息
    private func showStatus(_ message: String, isError: Bool) {
        statusMessage = message
        self.isError = isError

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.statusMessage = ""
        }
    }
}
