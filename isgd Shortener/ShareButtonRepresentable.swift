//
//  ShareButtonRepresentable.swift
//  isgd URL Shortener
//
//  Created by Lafin Lalannges on 2025/12/3.
//


import SwiftUI
import AppKit

struct ShareButtonRepresentable: NSViewRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard isPresented else { return }
        isPresented = false

        let picker = NSSharingServicePicker(items: items)
        picker.show(
            relativeTo: nsView.bounds,
            of: nsView,
            preferredEdge: .minY
        )
    }
}
