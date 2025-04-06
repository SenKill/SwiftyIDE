//
//  VerticalNavigationSplitView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 23.03.2025.
//

import SwiftUI
import AppKit

struct VerticalNavigationSplitView<EditorContent: View, OutputContent: View>: NSViewControllerRepresentable {
    let editorContent: EditorContent
    let outputContent: OutputContent
    
    init(@ViewBuilder editorContent: () -> EditorContent, @ViewBuilder outputContent: () -> OutputContent) {
        self.editorContent = editorContent()
        self.outputContent = outputContent()
    }
    
    func makeNSViewController(context: Context) -> NSSplitViewController {
        let splitVC = RatioSplitViewController()
        
        // Editor pane
        let editorItem = NSSplitViewItem(viewController: NSHostingController(rootView: editorContent))
        
        // Output pane
        let outputItem = NSSplitViewItem(viewController: NSHostingController(rootView: outputContent))
        
        // Minimum height
        editorItem.minimumThickness = 100
        outputItem.minimumThickness = 100
        
        // Setting split view controller's arrangement to be vertical
        splitVC.splitView.isVertical = false
        splitVC.addSplitViewItem(editorItem)
        splitVC.addSplitViewItem(outputItem)
        
        return splitVC
    }
    
    func updateNSViewController(_ nsViewController: NSSplitViewController, context: Context) {
        if let editorVC = nsViewController.splitViewItems[0].viewController as? NSHostingController<EditorContent> {
            editorVC.rootView = editorContent
        }
        if let outputVC = nsViewController.splitViewItems[1].viewController as? NSHostingController<OutputContent> {
            outputVC.rootView = outputContent
        }
    }
}

// Custom class only to set split views' default ratio
final fileprivate class RatioSplitViewController: NSSplitViewController {
    override func viewDidAppear() {
        super.viewDidAppear()
        setInitialSplitRatio()
    }
    
    private func setInitialSplitRatio() {
        let totalHeight = splitView.bounds.height
        let editorRatio = 0.7
        
        // Ensure valid size
        if totalHeight > 0 {
            let editorHeight = totalHeight * editorRatio
            splitView.setPosition(editorHeight, ofDividerAt: 0)
        }
    }
}
