//
//  EditorTextView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 09.03.2025.
//

import Cocoa
import SwiftUI

struct EditorTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 14, weight: .regular)
    
    var onEditingChanged: () -> Void       = {}
    var onCommit        : () -> Void       = {}
    var onTextChange    : (String) -> Void = { _ in }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> EditorTextNSView {
        let textView = EditorTextNSView(
            text: text,
            font: font,
            delegate: context.coordinator
        )
        return textView
    }
    
    func updateNSView(_ nsView: EditorTextNSView, context: Context) {
        nsView.text = text
        nsView.selectedRanges = context.coordinator.selectedRanges
    }
}

// MARK: - Coordinator
extension EditorTextView {
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorTextView
        var selectedRanges: [NSValue] = []
        
        init(_ parent: EditorTextView) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            
            self.parent.text = textView.string
            self.parent.onEditingChanged()
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            
            self.parent.text = textView.string
            self.selectedRanges = textView.selectedRanges
        }
        
        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            
            self.parent.text = textView.string
            self.parent.onCommit()
        }
    }
}

// MARK: - Custom Text View
final class EditorTextNSView: NSView {
    // MARK: - Properties
    var text: String {
        didSet {
            textView.string = text
            scrollView.verticalRulerView?.needsDisplay = true
            
            if !text.hasSuffix("\n") {
                textView.textStorage?.replaceCharacters(in: NSRange(location: textView.string.count, length: 0), with: "\n")
            }
        }
    }
    var selectedRanges: [NSValue] = [] {
        didSet {
            guard selectedRanges.count > 0 else {
                return
            }
            
            textView.selectedRanges = selectedRanges
        }
    }
    
    private weak var delegate: NSTextViewDelegate?
    private var font: NSFont?
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.backgroundColor         = NSColor.textBackgroundColor
        textView.delegate                = self.delegate
        textView.drawsBackground         = true
        textView.font                    = self.font
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable   = true
        textView.textColor               = NSColor.labelColor
        textView.allowsUndo              = true
        textView.isEditable = true
        textView.isSelectable = true
        return textView
    }()
    
    private lazy var scrollView: NSScrollView = {
        let sv = NSScrollView()
        sv.documentView = textView
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Init
    init(text: String, font: NSFont? = nil, delegate: NSTextViewDelegate) {
        self.font = font
        self.text = text
        self.delegate = delegate
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewWillDraw() {
        super.viewWillDraw()
        setUpConstraints()
        setupGutterView()
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
    
    private func setupGutterView() {
        let gutterView = EditorGutterNSView(textView: textView)
        scrollView.verticalRulerView = gutterView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
    }
}
