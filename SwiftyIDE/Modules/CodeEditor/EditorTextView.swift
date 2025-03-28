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
    var font: NSFont = Settings.defaultCodeFont
    
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
    final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: EditorTextView
        var selectedRanges: [NSValue] = []
        lazy private var syntaxHighlighter = SyntaxHighlighter(defaultFont: parent.font)
        
        init(_ parent: EditorTextView) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - NSTextViewDelegate
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
            // Add newline at the end of a file and set caret position back
            if !textView.string.hasSuffix("\n") {
                let caretRange = textView.selectedRange()
                textView.textStorage?.beginEditing()
                textView.textStorage?.replaceCharacters(in: caretRange, with: "\n")
                textView.textStorage?.endEditing()
                textView.setSelectedRange(caretRange)
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
        
        // MARK: - NSTextStorage Delegate
        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            // Track only those changes, where text storage updates whole text
            if editedMask.contains(.editedCharacters) && delta == 0 {
                self.syntaxHighlighter.highlightSyntax(in: textStorage, range: editedRange)
            }
        }
    }
}

// MARK: - Custom Text View
final class EditorTextNSView: NSView {
    // MARK: - Properties
    var text: String {
        didSet {
            textView.string = text
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
    
    private weak var delegate: (NSTextViewDelegate & NSTextStorageDelegate)?
    private var font: NSFont?
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.isRichText = false
        
        textView.font = self.font
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        
        textView.delegate = self.delegate
        textView.textStorage?.delegate = self.delegate
        
        // Disable soft wrapping, enable autoresizing
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineBreakMode = .byClipping
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
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
    
    // MARK: - Init
    init(text: String, font: NSFont? = nil, delegate: (NSTextViewDelegate & NSTextStorageDelegate)) {
        self.font = font
        self.text = text
        self.delegate = delegate
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(selectErrorPosition), name: .selectedErrorLink, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public methods
    func setSelection(at range: NSRange) {
        textView.setSelectedRange(range)
    }
    
    // MARK: - Life Cycle
    override func viewWillDraw() {
        super.viewWillDraw()
        setUpConstraints()
        setupGutterView()
    }
    
    // MARK: - Private methods
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
    
    @objc
    private func selectErrorPosition(notification: NSNotification) {
        guard let stringLink = notification.object as? String else { return }
        // Link looks like "row,col"
        let position = stringLink.components(separatedBy: ",")
        print(position)
        guard let row = Int(position.first ?? ""), let col = Int(position.last ?? "") else { return }
        let numberOfChars = getCharPosition(row: row, col: col, in: text)
        let errorRange = NSRange(location: numberOfChars, length: 0)
        textView.scrollRangeToVisible(errorRange)
        selectedRanges = [NSValue(range: errorRange)]
        textView.window?.makeFirstResponder(textView)
    }
    
    private func getCharPosition(row: Int, col: Int, in text: String) -> Int {
        var currentRow = 1
        var currentCol = 1
        var charCnt = 0
        
        // Count number of chars there are up to the target char position
        for ch in text {
            if currentRow == row && currentCol == col {
                break
            }
            if ch == "\n" {
                currentRow += 1
            } else if currentRow == row {
                currentCol += 1
            }
            charCnt += 1
        }
        return charCnt
    }
}
