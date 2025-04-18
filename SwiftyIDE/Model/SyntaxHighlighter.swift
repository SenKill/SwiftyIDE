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
                foregroundColor = .codeComments
                font = .defaultCodeFont
            case .strings:
                // Matches string literals, handling escaped quotes
                pattern = "\"(?:\\\\.|[^\"\\\\])*\""
                foregroundColor = .codeStrings
                font = .defaultCodeFont
            case .characters:
                // Matches character literals enclosed in single quotes
                pattern = "'(?:\\\\.|[^'\\\\]*)'"
                foregroundColor = .codeCharacters
                font = .defaultCodeFont
                
            case .numbers:
                // Matches integers and floating point numbers
                pattern = "\\b\\d+(?:\\.\\d+)?\\b"
                foregroundColor = .codeNumbers
                font = .defaultCodeFont
            case .keywords:
                // Matches keywords from a list
                let keywords: [String] = [
                    "class","enum","func","import","init",
                    "let","private","protocol","static","struct","var","break",
                    "case","continue","else","for","guard","if",
                    "return","switch","while","nil","self","true","false"
                ]
                
                pattern = "\\b(?:" + keywords.joined(separator: "|") + ")\\b"
                foregroundColor = .codeKeywords
                font = .boldCodeFont
                
            case .typeDeclarations:
                // Simply matches type names that commonly start with an uppercase letter
                pattern = "\\b[A-Z][A-Za-z0-9_]*\\b"
                foregroundColor = .codeTypeDeclarations
                font = .boldCodeFont
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
    let defaultColor: NSColor
    
    private var sortedCodeTypes: [CodeProperties] = CodeType.sortedTypes.map({ $0.properties })
    lazy private var joinedRegex: NSRegularExpression? = {
        let joinedPatterns = sortedCodeTypes.map { "(\($0.pattern))" }.joined(separator: "|")
        let regex: NSRegularExpression? = try? NSRegularExpression(pattern: joinedPatterns)
        return regex
    }()
    
    init(defaultFont: NSFont, defaultColor: NSColor) {
        self.defaultFont = defaultFont
        self.defaultColor = defaultColor
    }
    
    func highlightSyntax(in textStorage: NSTextStorage, range editedRange: NSRange) {
        let text = textStorage.string as NSString
        // Expand to full line
        let extendedRange = text.lineRange(for: editedRange)
        // Set the whole line to defaults
        textStorage.beginEditing()
        textStorage.setAttributes([
            .font: defaultFont,
            .foregroundColor: defaultColor
        ], range: extendedRange)
        // Check all code types
        guard let regex = joinedRegex else { return }
        // Use joined regex
        // Search for patterns in the line
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
