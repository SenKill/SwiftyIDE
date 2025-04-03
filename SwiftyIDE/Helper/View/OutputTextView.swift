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
        let textView = OutputTextNSView(delegate: context.coordinator)
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

// MARK: - NSTextViewDelegate
extension OutputTextView.Coordinator: NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        // Sends notification to EditorTextView
        NotificationCenter.default.post(name: .selectedErrorLink, object: link)
        return true
    }
}

// MARK: - OutputTextNSView
final class OutputTextNSView: NSView {
    weak var delegate: NSTextViewDelegate?
    
    // MARK: - Setting views
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.delegate = delegate
        
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        
        return textView
    }()
    
    private lazy var scrollView: NSScrollView = {
        let sv = NSScrollView()
        sv.documentView = textView
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = true
        // Hide scrollers when not in use
        sv.autohidesScrollers = true
        
        sv.contentInsets = .init(top: 8, left: 4, bottom: 4, right: 4)
        sv.automaticallyAdjustsContentInsets = false
        // Remove extra space around scrollbars
        sv.scrollerInsets = .init()

        sv.borderType = .noBorder
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
        if textLength > Settings.maxOutputLength {
            textView.string = ""
        } else {
            textView.scrollRangeToVisible(NSRange(location: textLength, length: 0))
        }
    }
    
    func clearText() {
        textView.textStorage?.setAttributedString(.init())
    }
    
    // MARK: - Life Cycle
    init(delegate: NSTextViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        scrollView.scrollerInsets = .init()
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
