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
    var font: NSFont = .defaultCodeFont
    var textColor: NSColor = .labelColor
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> EditorTextNSView {
        let textView = EditorTextNSView(
            text: text,
            font: font,
            textColor: textColor,
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
        lazy private var syntaxHighlighter = SyntaxHighlighter(defaultFont: parent.font, defaultColor: parent.textColor)
        
        init(_ parent: EditorTextView) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - NSTextViewDelegate
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
        
        func textView(_ textView: NSTextView,
                      shouldChangeTextIn range: NSRange,
                      replacementString string: String?) -> Bool {
            guard let textStorage = textView.textStorage else { return true }
            
            // Check if Enter key was pressed
            if string == "\n" {
                let indentLevel = calculateIndentation(textStorage: textStorage, range: range)
                if indentLevel == 0 { return true }
                let indentString = String(repeating: "\t", count: indentLevel)
                
                // Insert new line with proper indentation
                let newText = "\n" + indentString
                textView.insertText(newText, replacementRange: range)
                parent.text = textView.string
                return false // Prevent default behavior
            }
            
            // Check if new char is a closing bracket and remove 1 tab
            if string == "}" {
                let subString = textStorage.mutableString.substring(to: range.location)
                if subString.last == "\t" {
                    let deleteRange = NSRange(location: range.location-1, length: 1)
                    textStorage.mutableString.replaceCharacters(in: deleteRange, with: "}")
                    parent.text = textStorage.string
                    return false
                }
            }
            
            return true
        }
        
        /// Calculates how many tabulations should be inserted
        private func calculateIndentation(textStorage: NSTextStorage, range: NSRange) -> Int {
            let text = textStorage.string as NSString
            let textBeforeCursor = text.substring(to: range.location)
            
            var bracketCount = 0
            var hasComment: Bool = false
            var lastNewLine: Bool = false
            
            for char in textBeforeCursor {
                if char == "/" {
                    if lastNewLine {
                        hasComment = true
                    }
                    lastNewLine = true
                } else if char == "\n" {
                    hasComment = false
                } else {
                    lastNewLine = false
                }
                
                if !hasComment {
                    if char == "{" {
                        bracketCount += 1
                    } else if char == "}" {
                        bracketCount = max(0, bracketCount - 1)
                    }
                }
            }
            
            return bracketCount
        }
        
        // MARK: - NSTextStorageDelegate
        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            if editedMask.contains(.editedCharacters) {
                self.syntaxHighlighter.highlightSyntax(in: textStorage, range: editedRange)
            }
        }
    }
}

// MARK: - Custom Text View
final class EditorTextNSView: NSView {
    // MARK: - Properties
    var text: String
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
    private var textColor: NSColor?
    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.isRichText = false
        
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        textView.font = self.font
        textView.textColor = self.textColor
        textView.backgroundColor = .primaryBackground
        
        textView.typingAttributes = [
            .font: NSFont.defaultCodeFont,
            .foregroundColor: NSColor.labelColor
        ]
        
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
    init(text: String, font: NSFont? = nil, textColor: NSColor? = nil, delegate: (NSTextViewDelegate & NSTextStorageDelegate)) {
        self.font = font
        self.textColor = textColor
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
