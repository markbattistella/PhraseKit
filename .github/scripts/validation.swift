import Foundation

// Function to log messages
func log(_ message: String) {
    print(message)
    if let outputPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("validation_output.txt") {
        try? message.appendLineToURL(fileURL: outputPath)
    }
}

// Function to load the prohibited.json file
func loadProhibitedWords() -> Set<String>? {
    // Get the directory where the script is located
    let scriptDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    
    // Log the current working directory
    log("Current Directory: \(scriptDirectory.path)")
    
    // Append the prohibited.json file name to the directory path
    let prohibitedFilePath = scriptDirectory.appendingPathComponent("prohibited.json")
    
    // Log the full path to the prohibited.json file
    log("Looking for prohibited.json at: \(prohibitedFilePath.path)")
    
    // Attempt to load and parse the prohibited.json file
    guard let prohibitedData = try? Data(contentsOf: prohibitedFilePath),
          let prohibitedWords = try? JSONDecoder().decode([String].self, from: prohibitedData) else {
        log("Failed to load or parse prohibited.json")
        return nil
    }
    
    // Return the set of prohibited words in lowercase
    return Set(prohibitedWords.map { $0.lowercased() })
}

// Load the prohibited words
guard let blacklist = loadProhibitedWords() else {
    fatalError("Failed to load or parse prohibited.json")
}

// Function to process JSON files
func processJsonFile(at filePath: URL, rescanOptions: [String], index: Int, totalFiles: Int) {
    log("[\(index + 1) / \(totalFiles)] WORKING ON FILE")
    log("  - File: \"\(filePath.lastPathComponent)\"")
    
    guard let data = try? Data(contentsOf: filePath),
          var json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String]] else {
        log("  - Failed to read or parse JSON file")
        return
    }
    
    let pending = json["pending"] ?? []
    let safe = json["safe"] ?? []
    let unsafe = json["unsafe"] ?? []
    let incompatible = json["incompatible"] ?? []
    
    log("  - Initial counts:")
    log("      | Pending      | \(String(pending.count).padding(toLength: 6, withPad: " ", startingAt: 0))")
    log("      | Safe         | \(String(safe.count).padding(toLength: 6, withPad: " ", startingAt: 0))")
    log("      | Unsafe       | \(String(unsafe.count).padding(toLength: 6, withPad: " ", startingAt: 0))")
    log("      | Incompatible | \(String(incompatible.count).padding(toLength: 6, withPad: " ", startingAt: 0))")
    
    var newSafe = safe
    var newUnsafe = unsafe
    var newIncompatible = incompatible
    
    var movedToSafe = 0
    var movedToUnsafe = 0
    var movedToIncompatible = 0
    var skippedSafe = 0
    var skippedUnsafe = 0
    
    func processWords(_ words: [String], category: String) {
        log("  - Processing \"\(category)\" category with \(words.count) words")
        for word in words {
            let lowercasedWord = word.lowercased()
            if word.contains(" ") {
                newIncompatible.append(lowercasedWord)
                if category == "pending" { movedToIncompatible += 1 }
            } else if blacklist.contains(lowercasedWord) {
                newUnsafe.append(lowercasedWord)
                if category == "pending" { movedToUnsafe += 1 }
                else { skippedUnsafe += 1 }
            } else {
                newSafe.append(lowercasedWord)
                if category == "pending" { movedToSafe += 1 }
                else { skippedSafe += 1 }
            }
        }
    }
    
    if rescanOptions.contains("all") {
        newSafe.removeAll()
        newUnsafe.removeAll()
        newIncompatible.removeAll()
        processWords(pending, category: "pending")
        processWords(safe, category: "safe")
        processWords(unsafe, category: "unsafe")
    } else {
        if rescanOptions.isEmpty || rescanOptions.contains("pending") {
            processWords(pending, category: "pending")
        }
        if rescanOptions.contains("safe") {
            newSafe.removeAll()
            processWords(safe, category: "safe")
        }
        if rescanOptions.contains("unsafe") {
            newUnsafe.removeAll()
            processWords(unsafe, category: "unsafe")
        }
    }
    
    // Remove duplicates and sort the lists
    newSafe = Array(Set(newSafe)).sorted()
    newUnsafe = Array(Set(newUnsafe)).sorted()
    newIncompatible = Array(Set(newIncompatible)).sorted()
    
    let output: [String: [String]] = [
        "pending": [],
        "safe": newSafe,
        "unsafe": newUnsafe,
        "incompatible": newIncompatible
    ]
    
    // Compress (minify) the JSON and write it back to the file
    if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: []) { // No pretty print option
        try? jsonData.write(to: filePath)
    }
    
    log("  - Moved:")
    log("      | \(String(movedToSafe).padding(toLength: 5, withPad: " ", startingAt: 0)) words: Pending --> Safe")
    log("      | \(String(movedToUnsafe).padding(toLength: 5, withPad: " ", startingAt: 0)) words: Pending --> Unsafe")
    log("      | \(String(movedToIncompatible).padding(toLength: 5, withPad: " ", startingAt: 0)) words: Pending --> Incompatible")
    log("  - Skipped:")
    log("      | \(String(skippedSafe).padding(toLength: 5, withPad: " ", startingAt: 0)) words already in Safe")
    log("      | \(String(skippedUnsafe).padding(toLength: 5, withPad: " ", startingAt: 0)) words already in Unsafe")
    log("  - Processed and updated\n")
}

// Recursive function to get all JSON files in a directory
func getAllJsonFiles(at baseDir: URL) -> [URL] {
    var results = [URL]()
    if let enumerator = FileManager.default.enumerator(at: baseDir, includingPropertiesForKeys: nil) {
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "json" {
                results.append(fileURL)
            }
        }
    }
    return results
}

// Main function
func main(baseDir: URL, rescanOptionArg: String?) {
    let rescanOptions = rescanOptionArg?.components(separatedBy: ",") ?? []
    let files = getAllJsonFiles(at: baseDir)
    
    if files.isEmpty {
        log("No files found matching the pattern.")
        return
    }
    
    log("\n[i] FOUND \(files.count) JSON FILES\n")
    
    for (index, filePath) in files.enumerated() {
        processJsonFile(at: filePath, rescanOptions: rescanOptions, index: index, totalFiles: files.count)
    }
    
    log("[i] PROCESS COMPLETE")
}

// Get the base directory and rescan option from the command-line arguments
let arguments = CommandLine.arguments
if arguments.count < 2 {
    log("Usage: swift validation.swift <path/to/files> <rescan_option>")
    log("Rescan options: pending (default), safe, unsafe, all")
    exit(1)
}

let baseDir = URL(fileURLWithPath: arguments[1])
let rescanOptionArg = arguments.count > 2 ? arguments[2] : nil

main(baseDir: baseDir, rescanOptionArg: rescanOptionArg)

// Extension to append string to file
extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            try data.write(to: fileURL, options: .atomic)
        }
    }
}
