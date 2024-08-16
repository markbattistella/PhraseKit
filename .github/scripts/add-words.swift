import Foundation

// Define the structure of the JSON file
struct WordList: Codable {
    var pending: [String]
    var safe: [String]
    var unsafe: [String]
}

// Function to load or create a JSON file
func loadOrCreateJSON(at path: URL) -> WordList {
    if FileManager.default.fileExists(atPath: path.path) {
        do {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode(WordList.self, from: data)
        } catch {
            print("Failed to load or parse JSON at \(path.path):", error)
            exit(1)
        }
    } else {
        return WordList(pending: [], safe: [], unsafe: [])
    }
}

// Function to save JSON data
func saveJSON(_ data: WordList, to path: URL) {
    do {
        let jsonData = try JSONEncoder().encode(data)
        try jsonData.write(to: path, options: .atomic)
    } catch {
        print("Failed to save JSON at \(path.path):", error)
        exit(1)
    }
}

// Function to extract words from the issue body and validate them
func extractWords(from body: String) -> [String] {
    return body
        .split(separator: "\n")
        .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && $0.range(of: "^[a-z]+$", options: .regularExpression) != nil }
}

// Main function to process the words and update the JSON files
func main() {
    guard let body = ProcessInfo.processInfo.environment["GH_BODY"],
          let posList = ProcessInfo.processInfo.environment["POS"]?.split(separator: "\n").map({ $0.lowercased() }) else {
        print("Environment variables GH_BODY or POS are not set")
        exit(1)
    }

    let wordList = extractWords(from: body)

    guard !wordList.isEmpty else {
        print("No valid words provided.")
        exit(1)
    }

    // File paths
    let baseDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/PhraseKit/Resources")
    let fileMap: [String: URL] = [
        "adjective": baseDirectory.appendingPathComponent("_adjective.json"),
        "adverb": baseDirectory.appendingPathComponent("_adverb.json"),
        "noun": baseDirectory.appendingPathComponent("_noun.json"),
        "verb": baseDirectory.appendingPathComponent("_verb.json")
    ]

    // Ensure the base directory exists
    do {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Failed to create directory:", error)
        exit(1)
    }

    // Update the appropriate JSON files based on POS
    for pos in posList {
        if let jsonPath = fileMap[String(pos)] {
            var jsonData = loadOrCreateJSON(at: jsonPath)
            for word in wordList {
                if !jsonData.pending.contains(word) && !jsonData.safe.contains(word) && !jsonData.unsafe.contains(word) {
                    jsonData.pending.append(word)
                }
            }
            saveJSON(jsonData, to: jsonPath)
            print("Added words to \(pos) list in \(jsonPath.path)")
        } else {
            print("No JSON file found for POS: \(pos)")
        }
    }
}

main()
