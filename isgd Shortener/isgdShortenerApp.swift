//
//  isgdShortenerAPp.swift
//  isgd Shortener
//
//  這是一個把 iOS/IpadOS Safari.app縮短網址的功能，實現在電腦版 Safari.app上面的 App。
//  2025/12/25 新增 Safari Extension功能，目前暫無 Apple開發者的身分，因此啟用此功能需要使用者做其他設定才能使用。
//
//  Created by Lafin Lalannges on 2025/12/3.
//

import SwiftUI

@available(macOS 14.0, *)
@main
struct isgd_ShortenerApp: App {
    @State private var model = ShortenerModel()

    var body: some Scene {
        WindowGroup("URL 縮址工具") {
            ContentView(model: model)
                .frame(minWidth: 420, idealWidth: 440, maxWidth: 480,
                       minHeight: 260, idealHeight: 280, maxHeight: 320)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
