//
//  IDEViewModel.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 24.03.2025.
//

import SwiftUI
import Combine

final class IDEViewModel: ObservableObject {
    // For program output's attributes
    enum TerminationType: String {
        case warning
        case error
    }
    
    @Published var codeText: String = ""
    @Published var isScriptRunning: Bool = false
    @Published var didErrorHappen: Bool = false
    // Publisher to communicate with custom NSTextView on which is used to present output
    let outputAppendPublisher = PassthroughSubject<NSAttributedString?, Never>()
    
    private var runningProcess: Process?
    private var outputSource: DispatchSourceRead?
    
    func runScript() {
        runningProcess?.terminate()
        guard let url = saveScript() else {
            print("ERROR: Couldn't save the script")
            return
        }
        runScript(with: url)
    }
    
    func stopScript() {
        runningProcess?.terminate()
        runningProcess = nil
        outputSource?.cancel()
        outputSource = nil
    }
    
    func clearOutput() {
        // `nil` = clear output
        self.outputAppendPublisher.send(nil)
    }
    
    // Returns new script's url
    private func saveScript() -> URL? {
        // Save tmp file in temp directory
        let baseUrl = FileManager.default.temporaryDirectory
        let completeUrl = baseUrl.appendingPathComponent(Settings.standardScriptName)
        do {
            try codeText.write(to: completeUrl, atomically: true, encoding: .utf8)
            return completeUrl
        } catch let error as NSError {
            print("ERROR: An error happened during file writing \"\(error.localizedDescription)\"")
            return nil
        }
    }
    
    @discardableResult
    private func runScript(with url: URL) -> Bool {
        // To be sure :)
        stopScript()
        didErrorHappen = false
        // A class to run and track an executable
        // MARK: Doesn't show live output
        // TODO: Make live output
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // URL that searches for Swift compiler in PATH
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", url.path()]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            runningProcess = process
            isScriptRunning = true
            readOutputPipe(from: outputPipe)
            // Runs concurrently
            process.terminationHandler = onScriptTermination
            try process.run()
            return true
        } catch let error as NSError {
            print("ERROR: Failed to run script: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Private methods
private extension IDEViewModel {
    func readOutputPipe(from outputPipe: Pipe) {
        // Passing the output pipe's file descriptor and async queue to read from the output pipe to an DispatchSource object which is used to read data from streams
        self.outputSource = DispatchSource.makeReadSource(
            fileDescriptor: outputPipe.fileHandleForReading.fileDescriptor,
            queue: DispatchQueue.global(qos: .userInitiated))
        // Whenever there are any events check for new output
        outputSource?.setEventHandler { [weak self] in
            let data = outputPipe.fileHandleForReading.availableData
            if let outputString = try? NSMutableAttributedString(data: data, documentAttributes: nil) {
                
                // Style
                outputString.setAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: NSColor.black
                ], range: NSRange(location: 0, length: outputString.length))
                
                // Making changes on the main queue
                DispatchQueue.main.async {
                    self?.outputAppendPublisher.send(outputString)
                }
            }
        }
        outputSource?.resume()
    }
    
    @Sendable
    func onScriptTermination(_ process: Process?) {
        guard   let process = process,
                let errorPipe = process.standardError as? Pipe else {
            DispatchQueue.main.async {
                self.isScriptRunning = false
            }
            print("ERROR: Couldn't get script's process or error pipe")
            runningProcess = nil
            return
        }
        let errorData = try? errorPipe.fileHandleForReading.readToEnd()
        
        DispatchQueue.main.async {
            // Print out error/warning output if there any
            if let errorData = errorData,
               let error = String(data: errorData, encoding: .utf8) {
                let errorAttrString = NSMutableAttributedString(string: error)
                self.styleTerminationInfoString(errorAttrString)
                self.outputAppendPublisher.send(errorAttrString)
            }
            let returnCode = process.terminationStatus
            let termStatusAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: returnCode == 0
                    ? NSColor(red: 0, green: 0.6, blue: 0, alpha: 1)  // Success: Green
                    : NSColor(red: 0.8, green: 0.4, blue: 0, alpha: 1) // Failure: Orange
            ]
            let termStatusAttrString = NSAttributedString(string: "\nProcess exited with code \(returnCode)\n\n\n", attributes: termStatusAttributes)
            
            self.outputAppendPublisher.send(termStatusAttrString)
            self.isScriptRunning = false
            self.didErrorHappen = returnCode != 0
        }
        runningProcess = nil
        outputSource?.cancel()
        outputSource = nil
    }
    
    func styleTerminationInfoString(_ attributedString: NSMutableAttributedString) {
        // Example :1:5: warning:
        let pattern = ".*:([0-9]+):([0-9]+): ([a-z]+): ((?:.|\n)*?(?=\n\n|\\Z))"
        guard let regexWholeRange = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("ERROR: addClickableUrl() | Couldn't init regex")
            return
        }
        let errorString = attributedString.string
        let errorStringRange = NSRange(location: 0, length: errorString.count-1)
        
        regexWholeRange.enumerateMatches(in: errorString, range: errorStringRange) { match, _, _ in
            if let match = match {
                setGeneralAttributes(to: attributedString, for: match)
                addClickableUrl(to: attributedString, for: match)
            }
        }
    }
    
    func setGeneralAttributes(to termString: NSMutableAttributedString, for match: NSTextCheckingResult) {
        let wholeRange = match.range
        // Third group: termination type (error | warning)
        let terminationTypeNSRange = match.range(at: 3)
        
        guard let terminationTypeRange = Range(terminationTypeNSRange, in: termString.string),
              let termType = TerminationType(rawValue: String(termString.string[terminationTypeRange]))
        else {
            print("ERROR: setGeneralAttributes() | Couldn't get termination type")
            return
        }
        let attributes: [NSAttributedString.Key: Any]
        
        switch termType {
        case .warning:
            attributes = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
                .foregroundColor: NSColor(red: 1, green: 0.65, blue: 0, alpha: 1) // Orange
            ]
        case .error:
            attributes = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
                .foregroundColor: NSColor(red: 0.8, green: 0, blue: 0, alpha: 1) // Red
            ]
        }
        termString.setAttributes(attributes, range: wholeRange)
    }
    
    func addClickableUrl(to termString: NSMutableAttributedString, for match: NSTextCheckingResult) {
        let rowNSRange = match.range(at: 1)
        let columnNSRange = match.range(at: 2)
        if let (rowPosition, colPosition) = parseErrorsPosition(
            from: termString.string, rowNSRange: rowNSRange, columnNSRange: columnNSRange) {
            let combinedNSRange = NSRange(
                location: rowNSRange.location,
                length: rowNSRange.length + columnNSRange.length + 1)
            
            termString.addAttribute(.link, value: "\(rowPosition),\(colPosition)", range: combinedNSRange)
        }
    }
    
    // Match is of type NSTextCheckingResult and it's method range(at: ) returns range of the whole match or it's capture groups
    func parseErrorsPosition(from errorString: String, rowNSRange: NSRange, columnNSRange: NSRange) -> (Int, Int)? {
        guard let rowRange = Range(rowNSRange, in: errorString),
              let columnRange = Range(columnNSRange, in: errorString) else {
            print("ERROR: addClickableUrl() | Couldn't get range from nsranges")
            return nil
        }
        guard let rowPosition = Int(errorString[rowRange]),
              let columnPosition = Int(errorString[columnRange]) else {
            print("ERROR: addClickableUrl() | Couldn't get Int from position ranges")
            return nil
        }
        return (rowPosition, columnPosition)
    }
}
