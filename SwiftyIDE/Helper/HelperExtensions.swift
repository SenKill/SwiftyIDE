//
//  HelperExtensions.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 31.03.2025.
//

import AppKit

extension NSNotification.Name {
    static let selectedErrorLink: NSNotification.Name = .init(rawValue: "selectedErrorLink")
}

extension NSFont {
    static let defaultCodeFont: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    static let boldCodeFont: NSFont = .monospacedSystemFont(ofSize: 13, weight: .semibold)
    static let gutterLineFont: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    static let outputFont: NSFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    static let errorFont: NSFont = .monospacedSystemFont(ofSize: 12, weight: .bold)
    static let termStatusFont: NSFont = .monospacedSystemFont(ofSize: 12, weight: .medium)
}
