//
//  EditorGutterView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 07.03.2025.
//

import Cocoa
import SwiftUI

final class EditorGutterNSView: NSRulerView {
    weak var textView: NSTextView?
    private var selectedRanges: [NSValue] = []
    
    init(textView: NSTextView? = nil) {
        self.textView = textView
        super.init(scrollView: textView?.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = Settings.gutterWidth
        
        // Setting notification to update the gutter view when scrolling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentViewBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: textView?.enclosingScrollView?.contentView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChangeSelection),
            name: NSTextView.didChangeSelectionNotification,
            object: textView)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func contentViewBoundsDidChange(_ notification: Notification) {
        self.needsDisplay = true
    }
    
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        self.selectedRanges = textView?.selectedRanges ?? []
        self.needsDisplay = true
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }
        
        // Determine the visible glyph range based on the text view's visibleRect
        let visibleRect = textView.visibleRect
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let relativePoint = self.convert(NSZeroPoint, from: textView)
        // Starting glyph location of a row
        var glyphIndex = visibleGlyphRange.location
        // Retrieve selected character ranges from the text view
        let selectedCharRanges = textView.selectedRanges.compactMap { ($0 as NSValue).rangeValue }
        // Compute the number of lines preceding the visibleCharRange
        var lineNumber: Int = countOccurrences(in: textView.string, pattern: "\n", range: NSMakeRange(0, visibleGlyphRange.location))
        var lastLineRect: NSRect = .zero
        var lastLineHeight = lastLineRect.height
        
        while glyphIndex < visibleGlyphRange.upperBound {
            var effectiveRange = NSRange(location: 0, length: 0)
            
            // Get the line fragment rect
            lastLineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
            // Calculate the y position in the ruler view's coordinate system
            let yRulerPos = lastLineRect.origin.y + relativePoint.y
            var isLineSelected = false
            
            // Check if any of the selected ranges intersect with this line's character range
            if let selectedRange = selectedCharRanges.first {
                if selectedRange.length > 0 {
                    let maxSelection = selectedRange.location + selectedRange.length
                    isLineSelected = (effectiveRange.length + glyphIndex) > selectedRange.location && glyphIndex < maxSelection
                } else {
                    isLineSelected = selectedRange.location >= glyphIndex && selectedRange.location < effectiveRange.length + glyphIndex
                }
            }
            
            // Workaround to fix problem with empty string
            lastLineHeight = 17
            // Check if the line's rect intersects the drawing rect
            if yRulerPos + lastLineHeight >= rect.minY && yRulerPos <= rect.maxY {
                let yLinePos = yRulerPos + lastLineHeight / 2
                drawLineNumber(with: lineNumber, at: yLinePos, isSelected: isLineSelected)
            }
            // Move to the next line
            glyphIndex = effectiveRange.upperBound
            lineNumber += 1
        }
        
        // Draw last line
        let lastCharIndex = textView.string.utf16.count - 1
        if lastCharIndex >= 0 {
            // Calculate last char's glyph
            let lastGlyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: lastCharIndex, length: 1), actualCharacterRange: nil)
            
            // Calculate last ruler's y position based on previous' line rect
            let yRulerPos = lastLineRect.origin.y + relativePoint.y + lastLineHeight
            if yRulerPos + lastLineHeight >= rect.minY && yRulerPos <= rect.maxY {
                let yLinePos = yRulerPos + lastLineHeight / 2
                var isLineSelected = false
                if let selectedRange = selectedCharRanges.first {
                    isLineSelected = selectedRange.location == lastGlyphRange.upperBound
                }
                drawLineNumber(with: lineNumber, at: yLinePos, isSelected: isLineSelected)
            }
        }
    }
    
    func drawLineNumber(with lineNumber: Int, at yPosition: CGFloat, isSelected: Bool) {
        let label = "\(lineNumber)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.gutterLineFont,
            .foregroundColor: isSelected ? NSColor.labelColor : NSColor.secondaryLabelColor
        ]
        let attLabel = NSAttributedString(string: label, attributes: attributes)
        let labelSize = attLabel.size()
        let xPos = self.ruleThickness - labelSize.width - 5
        let yPos = yPosition - labelSize.height / 2.0
        attLabel.draw(at: NSPoint(x: xPos, y: yPos))
    }
    
    func countOccurrences(in text: String, pattern: String, range: NSRange) -> Int {
        var counter: Int = 1
        do {
            let newlineRegex = try NSRegularExpression(pattern: pattern)
            // Sum all newlines using regex from starting row to the last that isn't visible
            counter += newlineRegex.numberOfMatches(in: text, range: range)
        } catch {
            return counter
        }
        
        return counter
    }
}
