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
        print(self.selectedRanges)
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
        var glyphIndex = visibleGlyphRange.location
        // Retrieve selected character ranges from the text view
        let selectedCharRanges = textView.selectedRanges.compactMap { ($0 as NSValue).rangeValue }
        print(selectedCharRanges)
        
        // Computing the number of lines preceding the visibleCharRange.
        var lineNumber: Int = countOccurrences(in: textView.string, pattern: "\n", range: NSMakeRange(0, visibleGlyphRange.location))
        
        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            var effectiveRange = NSRange(location: 0, length: 0)
            // Get the line fragment rect even if it's empty.
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
            
            // Calculate the y position in the ruler view's coordinate system.
            let yPosition = lineRect.origin.y + relativePoint.y
            
            // Check if the line's rect intersects the drawing rect
            if yPosition + lineRect.height >= rect.minY && yPosition <= rect.maxY {
                let yPos = yPosition + lineRect.height / 2
                drawLineNumber(with: lineNumber, at: yPos)
            }
            
            // Convert the glyph range to a character range
            let charRange = layoutManager.characterRange(forGlyphRange: NSMakeRange(glyphIndex, effectiveRange.length), actualGlyphRange: nil)
            // Check if any of the selected ranges intersect with this line's character range.
            let isSelected = selectedCharRanges.contains { selectionRange in
                if selectionRange.length == 0 {
                    let isAtEnd = selectionRange.location >= textView.string.count && glyphIndex == NSMaxRange(visibleGlyphRange)-1
                    return NSLocationInRange(selectionRange.location, charRange) || isAtEnd
                } else {
                    return NSIntersectionRange(selectionRange, charRange).length > 0
                }
            }
                    
            // If the line is selected, draw a background rectangle in the gutter area.
            if isSelected {
                let bgRect = NSRect(x: 0, y: yPosition, width: self.ruleThickness, height: lineRect.height)
                Settings.selectionGutterColor.setFill() // Or a custom color
                bgRect.fill()
            }
            
            // Move to the next line fragment.
            glyphIndex = NSMaxRange(effectiveRange)
            lineNumber += 1
        }
    }
    
    func drawLineNumber(with lineNumber: Int, at yPosition: CGFloat) {
        let label = "\(lineNumber)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.gray
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
