//
//  isgdURLShortenerAPp.swift
//  isgd URL Shortener
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
