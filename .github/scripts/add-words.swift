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

// Function to load JSON from a file into a Dictionary
func loadJSON(from filePath: String) -> [String: Any]? {
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json
    } catch {
        print("Error loading JSON from file \(filePath): \(error)")
        return nil
    }
}

// Function to save a Dictionary as JSON to a file
func saveJSON(_ json: [String: Any], to filePath: String) {
    do {
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        let fileURL = URL(fileURLWithPath: filePath)
        try data.write(to: fileURL)
        print("Successfully updated \(filePath)")
    } catch {
        print("Error saving JSON to file \(filePath): \(error)")
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
        words = wordsSection.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
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

// Define the mapping between POS and JSON file paths
let jsonFiles: [String: String] = [
    "noun": "Sources/PhraseKit/Resources/_noun.json",
    "verb": "Sources/PhraseKit/Resources/_verb.json",
    "adjective": "Sources/PhraseKit/Resources/_adjective.json",
    "adverb": "Sources/PhraseKit/Resources/_adverb.json"
]

// Add words to the appropriate JSON files
for posItem in pos {
    if let filePath = jsonFiles[posItem] {
        if var json = loadJSON(from: filePath) {
            var pendingArray = json["pending"] as? [String] ?? []
            pendingArray.append(contentsOf: words)
            json["pending"] = pendingArray
            saveJSON(json, to: filePath)
        } else {
            print("Failed to load JSON for POS \(posItem) at path \(filePath)")
        }
    } else {
        print("No JSON file mapped for POS: \(posItem)")
    }
}
