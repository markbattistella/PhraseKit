import Foundation

// Define your validation logic
func validateWords(at path: String) throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let words = try JSONDecoder().decode([String].self, from: data)
    
    // Example validation: Ensure all words are non-empty strings
    for word in words {
        guard !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "Validation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Found an empty word"])
        }
    }
    
    print("All words are valid.")
}

func main() throws {
    let wordsFilePath = "words.json" // Adjust this path based on your project structure
    try validateWords(at: wordsFilePath)
}

do {
    try main()
} catch {
    print("Validation failed:", error)
    exit(1)
}
