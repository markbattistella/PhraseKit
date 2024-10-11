//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// `PhraseGenerator` is a class designed to generate random, human-readable phrases
/// composed of various parts of speech, such as adjectives, nouns, verbs, and adverbs.
@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
public class PhraseGenerator {

    /// A list of nouns used to generate phrases.
    internal var nouns: [String]

    /// A list of verbs used to generate phrases.
    internal var verbs: [String]

    /// A list of adjectives used to generate phrases.
    internal var adjectives: [String]

    /// A list of adverbs used to generate phrases.
    internal var adverbs: [String]

    /// A list of words provided by the user to generate phrases.
    private var customList: [String]

    /// A loader for custom word lists conforming to the `WordLoaderProtocol`.
    private var customLoader: WordLoaderProtocol?

    /// A list of words to exclude from phrase generation.
    private var exclusionList: [String]

    /// A set of previously generated word pairs to ensure uniqueness in phrase generation.
    ///
    /// This set keeps track of all the word pairs that have been generated so far, preventing
    /// duplicates and ensuring that each generated phrase is unique.
    private var usedPairs: Set<String>

    /// The types of word combinations that can be generated.
    public enum CombinationType: CaseIterable {
        case adjectiveNoun
        case verbNoun
        case adverbVerb
        case adverbAdjective
        case nounNoun
        case adjectiveAdjective
        case custom
    }

    /// The number of words in the generated phrase.
    public enum WordCount: Int {
        case two = 2
        case three = 3
    }

    /// Initializes the `PhraseGenerator` with word lists loaded from JSON files.
    ///
    /// This designated initializer loads the default word lists for nouns, verbs, adjectives,
    /// and adverbs from the JSON files in the module's bundle.
    public init(exclusionList: [String] = []) {
        self.nouns = WordLoader.loadWords(from: "_noun")
        self.verbs = WordLoader.loadWords(from: "_verb")
        self.adjectives = WordLoader.loadWords(from: "_adjective")
        self.adverbs = WordLoader.loadWords(from: "_adverb")
        self.customList = []
        self.customLoader = nil
        self.exclusionList = exclusionList
        self.usedPairs = []
        self.applyExclusionList()
    }

    /// Initializes the `PhraseGenerator` with word lists loaded from JSON files or a custom loader.
    ///
    /// This convenience initializer allows the user to pass in a custom loader conforming to
    /// `WordLoaderProtocol`. If a custom loader is provided, it loads the custom word list
    /// and clears the internal lists. If no custom loader is provided, it calls the designated
    /// initializer to load the default word lists.
    ///
    /// - Parameter customLoader: An optional loader conforming to `WordLoaderProtocol`, used to
    /// load custom word lists.
    public convenience init(customLoader: WordLoaderProtocol? = nil, exclusionList: [String] = []) {
        self.init(exclusionList: exclusionList)
        if let loader = customLoader {
            self.customLoader = loader
            self.customList = loader.loadWords()
            self.clearInternalWordLists()
        }
    }
}

// MARK: - Public methods

public extension PhraseGenerator {

    /// Generates a random phrase with the specified word count and combination type.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase (default is two).
    ///   - combinationType: The specific type of word combination to generate (optional).
    /// - Returns: A string containing the generated phrase, or `nil` if no valid phrase could
    /// be generated.
    func generatePhrase(
        wordCount: WordCount = .two,
        combinationType: CombinationType? = nil
    ) -> String? {
        switch wordCount {
            case .two:
                return generateTwoWordPhrase(combinationType: combinationType)
            case .three:
                return generateThreeWordPhrase(combinationType: combinationType)
        }
    }

    /// Generates a unique phrase and throws an error if all combinations are exhausted.
    ///
    /// - Throws: `PhraseGenerationError.allCombinationsUsed` if no more unique phrases can be
    /// generated.
    /// - Returns: A unique phrase string.
    func generate() throws -> String {
        if let phrase = generatePhrase() {
            return phrase
        } else {
            throw PhraseGenerationError.allCombinationsUsed
        }
    }

    /// Generates a unique phrase or returns a default phrase if all combinations are exhausted.
    ///
    /// - Parameter defaultPhrase: The phrase to return if no more unique phrases can be generated.
    /// - Returns: A unique phrase string or the provided default phrase.
    func generate(withDefault defaultPhrase: String) -> String {
        return generatePhrase() ?? defaultPhrase
    }

    /// Generates a unique phrase or returns a custom message if all combinations are exhausted.
    ///
    /// - Parameter message: The message to return if no more unique phrases can be generated.
    /// - Returns: A unique phrase string or the provided custom message.
    func generate(withMessage message: String = "All combinations used") -> String {
        return generatePhrase() ?? message
    }

    /// A computed property that generates a unique phrase silently, returning an empty string
    /// if all combinations are exhausted.
    var uniquePhrase: String {
        return generatePhrase() ?? ""
    }

    /// Returns the count of possible word combinations for a given word count and combination type.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase.
    ///   - combinationType: The type of word combination.
    /// - Returns: The number of possible combinations.
    func getWordCombinationCount(
        for wordCount: WordCount,
        combinationType: CombinationType? = nil
    ) -> Int {
        let type = combinationType ?? (customLoader != nil ? .custom : .adjectiveNoun)
        return calculateCombinationCount(for: wordCount, combinationType: type)
    }

    /// Returns the number of remaining combinations for a given word count and combination type.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase.
    ///   - combinationType: The type of word combination.
    /// - Returns: The number of remaining combinations.
    func getRemainingCombinations(
        for wordCount: WordCount,
        combinationType: CombinationType? = nil
    ) -> Int {
        let totalCombinations = getWordCombinationCount(
            for: wordCount,
            combinationType: combinationType
        )
        return totalCombinations - usedPairs.count
    }

    /// Resets the list of used word pairs.
    func resetUsedPairs() {
        usedPairs.removeAll()
    }
}

// MARK: - Private Methods

fileprivate extension PhraseGenerator {

    /// Applies the exclusion list to all word lists, removing any excluded words and updates
    /// the lists.
    private func applyExclusionList() {
        nouns = nouns.filter { !exclusionList.contains($0) }
        verbs = verbs.filter { !exclusionList.contains($0) }
        adjectives = adjectives.filter { !exclusionList.contains($0) }
        adverbs = adverbs.filter { !exclusionList.contains($0) }
        customList = customList.filter { !exclusionList.contains($0) }
    }

    /// Calculates the number of possible combinations for the given word count and combination
    /// type.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase.
    ///   - combinationType: The type of word combination.
    /// - Returns: The number of possible combinations.
    private func calculateCombinationCount(
        for wordCount: WordCount,
        combinationType: CombinationType
    ) -> Int {
        let (list1, list2): ([String], [String]) = {
            switch combinationType {
                case .adjectiveNoun:
                    return (adjectives, nouns)
                case .verbNoun:
                    return (verbs, nouns)
                case .adverbVerb:
                    return (adverbs, verbs)
                case .adverbAdjective:
                    return (adverbs, adjectives)
                case .nounNoun:
                    return (nouns, nouns)
                case .adjectiveAdjective:
                    return (adjectives, adjectives)
                case .custom:
                    return (customList, customList)
            }
        }()

        // Ensure that excluded words are not counted
        let filteredList1 = list1.filter { !exclusionList.contains($0) }
        let filteredList2 = list2.filter { !exclusionList.contains($0) }

        guard !filteredList1.isEmpty && !filteredList2.isEmpty else { return 0 }
        let twoWordCombinations = filteredList1.count * filteredList2.count
        return wordCount == .two ? twoWordCombinations : twoWordCombinations * filteredList1.count
    }

    /// Generates a two-word phrase based on the specified combination type.
    ///
    /// - Parameter combinationType: The type of word combination.
    /// - Returns: A generated two-word phrase as a string, or nil if no unique phrase can be
    /// generated.
    private func generateTwoWordPhrase(combinationType: CombinationType? = nil) -> String? {
        var pair: String
        repeat {
            pair = generateWordPair(combinationType: combinationType) ?? ""
        } while usedPairs.contains(pair)
        if usedPairs.count >= getWordCombinationCount(for: .two, combinationType: combinationType) {
            return nil
        }
        usedPairs.insert(pair)
        return pair
    }

    /// Generates a three-word phrase based on the specified combination type.
    ///
    /// - Parameter combinationType: The type of word combination.
    /// - Returns: A generated three-word phrase as a string, or nil if no unique phrase can be
    /// generated.
    private func generateThreeWordPhrase(combinationType: CombinationType? = nil) -> String? {
        var triplet: String
        repeat {
            let firstPart = generateWordPair(combinationType: combinationType) ?? ""
            let randomWord = nouns.randomElement() ?? ""
            triplet = "\(firstPart)-\(randomWord)"
        } while usedPairs.contains(triplet)

        if usedPairs.count >= getWordCombinationCount(for: .three, combinationType: combinationType) {
            return nil
        }

        usedPairs.insert(triplet)
        return triplet
    }

    /// Generates a word pair based on the specified combination type or a random one if not
    /// specified.
    ///
    /// - Parameter combinationType: The type of word combination.
    /// - Returns: A generated word pair as a string, or nil if no word pair can be generated.
    private func generateWordPair(combinationType: CombinationType? = nil) -> String? {
        let type = combinationType ?? CombinationType.allCases.randomElement()!
        return generatePair(from: type)
    }

    /// Generates a pair of words based on the specified combination type.
    ///
    /// - Parameter combinationType: The type of word combination.
    /// - Returns: A generated word pair as a string.
    private func generatePair(from combinationType: CombinationType) -> String? {
        let (list1, list2): ([String], [String]) = {
            switch combinationType {
                case .adjectiveNoun:
                    return (adjectives, nouns)
                case .verbNoun:
                    return (verbs, nouns)
                case .adverbVerb:
                    return (adverbs, verbs)
                case .adverbAdjective:
                    return (adverbs, adjectives)
                case .nounNoun:
                    return (nouns, nouns)
                case .adjectiveAdjective:
                    return (adjectives, adjectives)
                case .custom:
                    return (customList, customList)
            }
        }()

        let word1 = list1.randomElement() ?? ""
        let word2 = list2.randomElement() ?? ""
        return "\(word1)-\(word2)"
    }

    /// Clears the internal word lists, setting them to empty arrays.
    private func clearInternalWordLists() {
        self.nouns = []
        self.verbs = []
        self.adjectives = []
        self.adverbs = []
    }
}
