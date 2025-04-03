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
    static private func loadCustomFont(named name: String, size: CGFloat) -> NSFont {
        guard let font = NSFont(name: name, size: size) else {
            fatalError("Failed to load font: \(name). Ensure it's added to the assets and Info.plist")
        }
        return font
    }
    
    static let defaultCodeFont: NSFont = .loadCustomFont(named: "JetBrainsMono-Regular", size: 13)
    static let boldCodeFont: NSFont = .loadCustomFont(named: "JetBrainsMono-SemiBold", size: 13)
    static let gutterLineFont: NSFont = .loadCustomFont(named: "JetBrainsMono-Light", size: 11)
    static let outputFont: NSFont = .loadCustomFont(named: "JetBrainsMono-Regular", size: 13)
    static let errorFont: NSFont = .loadCustomFont(named: "JetBrainsMono-Bold", size: 12)
    static let termStatusFont: NSFont = .loadCustomFont(named: "JetBrainsMono-Medium", size: 13)
}
