//
//  ContentView.swift
//  isgd URL Shortener
//
//  Created by Lafin Lalannges on 2025/12/3.
//

// import AppKit是分享面板跳出的關鍵
import SwiftUI
import AppKit

@available(macOS 14.0, *)
struct ContentView: View {
    @Bindable var model: ShortenerModel

    // 觸發系統的分享功能面板
    @State private var isShowingSharePicker = false

    var body: some View {
        VStack(spacing: 16) {
            // 標題
            VStack(alignment: .leading, spacing: 4) {
                Text("URL 縮址工具")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("使用 is.gd 服務快速縮短網址")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 卡片
            VStack(spacing: 16) {
                // 輸入欄
                VStack(alignment: .leading, spacing: 8) {
                    Text("輸入要縮短的網址")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("例如：https://www.example.com/very/long/url",
                              text: $model.inputURL)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .onSubmit { model.shorten() }
                }

                // 按鈕列
                HStack(spacing: 12) {
                    Button {
                        model.shorten()
                    } label: {
                        HStack(spacing: 6) {
                            if model.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "link.circle")
                            }
                            Text(model.isLoading ? "處理中…" : "縮短網址")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading || model.inputURL.isEmpty)

                    Button {
                        model.inputURL = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .help("清除")
                }

                // 狀態訊息
                if !model.statusMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: model.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(model.isError ? .red : .green)
                        Text(model.statusMessage)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(8)
                    .background(model.isError ? Color.red.opacity(0.08) : Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // 結果
                if !model.shortURL.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("縮短的網址")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("", text: .constant(model.shortURL))
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)

                            Button {
                                model.copyToClipboard()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("複製到剪貼簿")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("分享方式")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                // 系統分享面板（社群、訊息、AirDrop 等）
                                // Button {
                                //     isShowingSharePicker = true
                                // } label: {
                                //     Label("分享", systemImage: "square.and.arrow.up")
                                // }
                                // .buttonStyle(.bordered)
                                // .disabled(model.shortURL.isEmpty)
                                ShareButton(items: [model.shortURL])
                                    .frame(width: 70)
                                    .disabled(model.shortURL.isEmpty)

                                // Button {
                                //     model.shareViaAirDrop()
                                // } label: {
                                //     Label("AirDrop", systemImage: "airplayvideo")
                                // }
                                // .buttonStyle(.bordered)

                                Button {
                                    model.shareViaMail()
                                } label: {
                                    Label("郵件", systemImage: "envelope")
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    model.openInBrowser()
                                } label: {
                                    Label("在瀏覽器開啟", systemImage: "safari")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    // 隱藏的 bridge，用來叫 NSSharingServicePicker
                    // shareView
                    // .background(
                    //    SharePickerBridge(
                    //        isPresented: $isShowingSharePicker,
                    //        items: [model.shortURL]
                    //    )
                    //    .frame(width: 0, height: 0)
                    // )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

// Share sheet bridge
import AppKit

struct ShareButton: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "分享",
                              target: context.coordinator,
                              action: #selector(Coordinator.share))
        button.bezelStyle = .rounded
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.items = items
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items)
    }

    class Coordinator: NSObject {
        var items: [Any]

        init(items: [Any]) {
            self.items = items
        }

        @objc func share(_ sender: NSButton) {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}


