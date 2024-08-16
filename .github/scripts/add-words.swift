import Foundation

// Function to read the contents of a file
func readFileContent(from filePath: String) -> String? {
    do {
        let fileURL = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content
    } catch {
        print("Error reading file: \(error)")
        return nil
    }
}

// Ensure the script received the correct number of arguments
guard CommandLine.arguments.count > 1 else {
    print("Usage: swift add-words.swift <file_path>")
    exit(1)
}

// Get the file path from the command-line arguments
let filePath = CommandLine.arguments[1]

// Read the issue body content from the file
guard let issueBody = readFileContent(from: filePath) else {
    print("Failed to read issue body content from file.")
    exit(1)
}

// Extracting the words
let wordsSectionRegex = try! NSRegularExpression(pattern: "### New Words\\s+([\\s\\S]+?)###", options: .caseInsensitive)
let wordsMatches = wordsSectionRegex.matches(in: issueBody, options: [], range: NSRange(issueBody.startIndex..., in: issueBody))

var words = [String]()
if let match = wordsMatches.first {
    let range = match.range(at: 1)
    if let swiftRange = Range(range, in: issueBody) {
        let wordsSection = issueBody[swiftRange].trimmingCharacters(in: .whitespacesAndNewlines)
        words = wordsSection.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

// Extracting the POS
let posSectionRegex = try! NSRegularExpression(pattern: "### Parts of Speech \\(POS\\)\\s+(.+)", options: .caseInsensitive)
let posMatches = posSectionRegex.matches(in: issueBody, options: [], range: NSRange(issueBody.startIndex..., in: issueBody))

var pos = [String]()
if let match = posMatches.first {
    let range = match.range(at: 1)
    if let swiftRange = Range(range, in: issueBody) {
        let posSection = issueBody[swiftRange].trimmingCharacters(in: .whitespacesAndNewlines)
        pos = posSection.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    }
}

// Creating the JSON structure
let result: [String: Any] = [
    "words": words,
    "pos": pos
]

// Convert the result to JSON
if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted]) {
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
}
