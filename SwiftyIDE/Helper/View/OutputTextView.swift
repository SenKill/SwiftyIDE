//
//  OutputTextView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 25.03.2025.
//

import SwiftUI
import AppKit
import Combine

struct OutputTextView: NSViewRepresentable {
    let appendPublisher: PassthroughSubject<NSAttributedString?, Never>
    
    func makeNSView(context: Context) -> OutputTextNSView {
        let textView = OutputTextNSView()
        context.coordinator.setupSubscriptions(appendPublisher: appendPublisher, textView: textView)
        return textView
    }
    
    func updateNSView(_ nsView: OutputTextNSView, context: Context) {
        // All changes are happening through `appendPublisher`
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: NSObject {
        var cancellables = Set<AnyCancellable>()
        
        func setupSubscriptions(appendPublisher: PassthroughSubject<NSAttributedString?, Never>, textView: OutputTextNSView) {
            appendPublisher
                .sink { [weak textView] newText in
                    guard let textView = textView else { return }
                    // If nil set then clear the text
                    if let newText = newText {
                        textView.appendText(newText)
                    } else {
                        textView.clearText()
                    }
                }
                .store(in: &cancellables)
        }
    }
}

final class OutputTextNSView: NSView {
    // MARK: - Setting views
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        
        return textView
    }()
    
    private lazy var scrollView: NSScrollView = {
        let sv = NSScrollView()
        sv.documentView = textView
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = true
        sv.autohidesScrollers = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    func appendText(_ text: NSAttributedString) {
        textView.textStorage?.append(text)
        let textLength = textView.textStorage?.length ?? 0
        textView.scrollRangeToVisible(NSRange(location: textLength, length: 0))
    }
    
    func clearText() {
        textView.textStorage?.setAttributedString(.init())
    }
    
    // MARK: - Life Cycle
    init() {
        super.init(frame: .zero)
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
