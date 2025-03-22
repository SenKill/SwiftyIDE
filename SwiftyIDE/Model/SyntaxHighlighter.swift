//
//  SyntaxHighlighter.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 15.03.2025.
//

import Foundation
import AppKit

final class SyntaxHighlighter {
    struct CodeProperties {
        let regex: NSRegularExpression?
        let pattern: String
        let attributes: [NSAttributedString.Key: Any]
    }
    
    enum CodeType {
        case comments
        case strings
        case characters
        case numbers
        case keywords
        case typeDeclarations
        
        static let sortedTypes: [CodeType] = [
            characters, numbers, keywords, typeDeclarations, strings, comments
        ]
        
        var properties: CodeProperties {
            let pattern: String
            let foregroundColor: NSColor
            let font: NSFont
            
            switch self {
            case .comments:
                // Matches regular and multiline comments
                pattern = "(\\/\\*[\\s\\S]*?(\\*\\/))|(\\/\\*[\\s\\S]*$)|(//.*)"
                foregroundColor = NSColor(red: 38/255, green: 117/255, blue: 7/255, alpha: 1)
                font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            case .strings:
                // Matches string literals, handling escaped quotes
                pattern = "\"(?:\\\\.|[^\"\\\\])*\""
                foregroundColor = NSColor.systemRed
                font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            case .characters:
                // Matches character literals enclosed in single quotes
                pattern = "'(?:\\\\.|[^'\\\\]*)'"
                foregroundColor = NSColor.systemOrange
                font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                
            case .numbers:
                // Matches integers and floating point numbers
                pattern = "\\b\\d+(?:\\.\\d+)?\\b"
                foregroundColor = NSColor.systemPink
                font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            case .keywords:
                // Matches keywords from a list
                let keywords: [String] = [
                    "class","enum","func","import","init",
                    "let","private","protocol","static","struct","var","break",
                    "case","continue","else","for","guard","if",
                    "return","switch","while","nil","self","true","false"
                ]
                
                pattern = "\\b(?:" + keywords.joined(separator: "|") + ")\\b"
                foregroundColor = NSColor.systemBlue
                font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
                
            case .typeDeclarations:
                // Simply matches type names that commonly start with an uppercase letter
                pattern = "\\b[A-Z][A-Za-z0-9_]*\\b"
                foregroundColor = NSColor.systemPurple
                font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
            }
            let regex = try? NSRegularExpression(pattern: pattern)
            let attrKeys: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: foregroundColor
            ]
            return CodeProperties(regex: regex, pattern: pattern, attributes: attrKeys)
        }
    }
    
    let defaultFont: NSFont
    private var sortedCodeTypes: [CodeProperties] = CodeType.sortedTypes.map({ $0.properties })
    lazy private var joinedRegex: NSRegularExpression? = {
        let joinedPatterns = sortedCodeTypes.map { "(\($0.pattern))" }.joined(separator: "|")
        let regex: NSRegularExpression? = try? NSRegularExpression(pattern: joinedPatterns)
        return regex
    }()
    
    init(defaultFont: NSFont) {
        self.defaultFont = defaultFont
    }
    
    func highlightSyntax(in textStorage: NSTextStorage, range editedRange: NSRange) {
        let text = textStorage.string as NSString
        // Expand to full line
        let extendedRange = text.lineRange(for: editedRange)
        
        textStorage.beginEditing()
        textStorage.removeAttribute(.foregroundColor, range: extendedRange)
        // Check all code types
        guard let regex = joinedRegex else { return }
        // Use joined regex
        regex.enumerateMatches(in: textStorage.string, range: extendedRange) { match, _, _ in
            guard let match = match else { return }
            // 0 - all matches, 1 - match for 1. regex group etc...
            for i in 1..<match.numberOfRanges {
                let range = match.range(at: i)
                if range.location != NSNotFound {
                    let attributes = sortedCodeTypes[i-1].attributes
                    textStorage.addAttributes(attributes, range: range)
                    break
                }
            }
        }
        textStorage.endEditing()
    }
}
