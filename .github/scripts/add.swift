import Foundation

struct Words: Codable {
    var pending: [String]
    var safe: [String]
    var unsafe: [String]
}

func loadWords(at path: String) throws -> Words {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(Words.self, from: data)
}

func saveWords(_ words: Words, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let data = try encoder.encode(words)
    try data.write(to: URL(fileURLWithPath: path))
}

func main() throws {
    guard let body = ProcessInfo.processInfo.environment["GH_BODY"] else {
        print("Body (GH_BODY) not set")
        exit(1)
    }

    let wordCategories = ["Adjective", "Adverb", "Noun", "Verb"]
    let files = [
        "Adjective": "Sources/PhraseKit/Resources/_adjective.json",
        "Adverb": "Sources/PhraseKit/Resources/_adverb.json",
        "Noun": "Sources/PhraseKit/Resources/_noun.json",
        "Verb": "Sources/PhraseKit/Resources/_verb.json"
    ]
    
    var wordDict: [String: [String]] = [:]
    
    let lines = body.split(separator: "\n")
    var currentCategory: String? = nil
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if wordCategories.contains(trimmedLine) {
            currentCategory = trimmedLine
            wordDict[currentCategory!] = []
        } else if let category = currentCategory {
            wordDict[category]?.append(trimmedLine.lowercased())
        }
    }
    
    for (category, words) in wordDict {
        guard let path = files[category] else { continue }
        
        var currentWords = try loadWords(at: path)
        let validWords = words.filter { $0.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil }
        
        currentWords.pending.append(contentsOf: validWords)
        currentWords.pending = Array(Set(currentWords.pending)).sorted()  // Remove duplicates and sort
        
        try saveWords(currentWords, to: path)
        
        print("Added \(validWords.count) \(category) words to \(path)")
    }
}

try main()
