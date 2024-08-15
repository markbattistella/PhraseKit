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
    private var nouns: [String]

    /// A list of verbs used to generate phrases.
    private var verbs: [String]

    /// A list of adjectives used to generate phrases.
    private var adjectives: [String]

    /// A list of adverbs used to generate phrases.
    private var adverbs: [String]

    /// A list of words provided by the user to generate phrases.
    private var customList: [String]

    /// A loader for custom word lists conforming to the `WordLoaderProtocol`.
    private var customLoader: WordLoaderProtocol?

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
    public init() {
        self.nouns = WordLoader.loadWords(from: "_noun")
        self.verbs = WordLoader.loadWords(from: "_verb")
        self.adjectives = WordLoader.loadWords(from: "_adjective")
        self.adverbs = WordLoader.loadWords(from: "_adverb")
        self.customList = []
        self.customLoader = nil
        self.usedPairs = []
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
    public convenience init(customLoader: WordLoaderProtocol? = nil) {
        if let loader = customLoader {
            self.init()
            self.customLoader = loader
            self.customList = loader.loadWords()
            self.nouns = []
            self.verbs = []
            self.adjectives = []
            self.adverbs = []
        } else {
            self.init()
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
    func generateUniquePhrase() throws -> String {
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
    func generateUniquePhrase(orDefault defaultPhrase: String) -> String {
        return generatePhrase() ?? defaultPhrase
    }

    /// Generates a unique phrase or returns a custom message if all combinations are exhausted.
    ///
    /// - Parameter message: The message to return if no more unique phrases can be generated.
    /// - Returns: A unique phrase string or the provided custom message.
    func generateUniquePhrase(orMessage message: String = "All combinations used") -> String {
        return generatePhrase() ?? message
    }

    /// A computed property that generates a unique phrase silently, returning an empty string
    /// if all combinations are exhausted.
    var uniquePhrase: String {
        return generatePhrase() ?? ""
    }

    /// Calculates the total number of possible word combinations for a custom word list.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase (either two or three).
    ///   - customWords: The custom word list provided by the user.
    /// - Returns: The total number of possible word combinations using the custom word list.
    func getCustomWordCombinationCount(
        for wordCount: WordCount,
        with customWords: [String]
    ) -> Int {
        guard !customWords.isEmpty else { return 0 }
        let customCount = customWords.count * (customWords.count - 1)
        return wordCount == .two ? customCount : customCount * customWords.count
    }

    /// Calculates the remaining number of possible word combinations for a custom word list.
    ///
    /// - Parameters:
    ///   - wordCount: The number of words in the phrase (either two or three).
    ///   - customWords: The custom word list provided by the user.
    /// - Returns: The number of remaining unused word combinations using the custom word list.
    func getRemainingCustomCombinations(
        for wordCount: WordCount,
        with customWords: [String]
    ) -> Int {
        let totalCombinations = getCustomWordCombinationCount(for: wordCount, with: customWords)
        return totalCombinations - usedPairs.count
    }

    /// Resets the set of used pairs, allowing phrases to be generated again without duplicates.
    func resetUsedPairs() {
        usedPairs.removeAll()
    }
}

// MARK: - Private methods

private extension PhraseGenerator {

    /// Generates a two-word phrase with the specified combination type.
    ///
    /// - Parameter combinationType: The specific type of word combination to generate (optional).
    /// - Returns: A string containing the generated phrase, or `nil` if no valid phrase could
    /// be generated.
    private func generateTwoWordPhrase(combinationType: CombinationType? = nil) -> String? {
        var pair: String
        repeat {
            pair = generateWordPair(combinationType: combinationType) ?? ""
        } while usedPairs.contains(pair)

        if usedPairs.count >= getInternalWordCombinationCount(for: .two) {
            return nil
        }

        usedPairs.insert(pair)
        return pair
    }

    /// Generates a three-word phrase with the specified combination type.
    ///
    /// - Parameter combinationType: The specific type of word combination to generate (optional).
    /// - Returns: A string containing the generated phrase, or `nil` if no valid phrase could
    /// be generated.
    private func generateThreeWordPhrase(combinationType: CombinationType? = nil) -> String? {
        var triplet: String
        repeat {
            let firstPart = generateWordPair(combinationType: combinationType) ?? ""
            let randomWord = nouns.randomElement() ?? ""
            triplet = "\(firstPart)-\(randomWord)"
        } while usedPairs.contains(triplet)

        if usedPairs.count >= getInternalWordCombinationCount(for: .three) {
            return nil
        }

        usedPairs.insert(triplet)
        return triplet
    }

    /// Generates a word pair based on the specified combination type.
    ///
    /// - Parameter combinationType: The specific type of word combination to generate (optional).
    /// - Returns: A string containing the generated word pair, or `nil` if no valid pair could
    /// be generated.
    private func generateWordPair(combinationType: CombinationType? = nil) -> String? {
        let type = combinationType ?? CombinationType.allCases.randomElement()!
        var pair: String

        switch type {
            case .adjectiveNoun:
                pair = generatePair(from: adjectives, and: nouns)
            case .verbNoun:
                pair = generatePair(from: verbs, and: nouns)
            case .adverbVerb:
                pair = generatePair(from: adverbs, and: verbs)
            case .adverbAdjective:
                pair = generatePair(from: adverbs, and: adjectives)
            case .nounNoun:
                pair = generatePair(from: nouns, and: nouns)
            case .adjectiveAdjective:
                pair = generatePair(from: adjectives, and: adjectives)
            case .custom:
                pair = generatePair(from: customList, and: customList)
        }

        return pair
    }
    
    /// Calculates the total number of possible word combinations for the specified word count
    /// using internal word lists.
    ///
    /// - Parameter wordCount: The number of words in the phrase (either two or three).
    /// - Returns: The total number of possible word combinations.
    private func getInternalWordCombinationCount(for wordCount: WordCount) -> Int {
        let adjectiveNounCount = adjectives.count * nouns.count
        let verbNounCount = verbs.count * nouns.count
        let adverbVerbCount = adverbs.count * verbs.count
        let adverbAdjectiveCount = adverbs.count * adjectives.count
        let nounNounCount = nouns.count * (nouns.count - 1)
        let adjectiveAdjectiveCount = adjectives.count * (adjectives.count - 1)

        let twoWordCombinations = adjectiveNounCount +
        verbNounCount +
        adverbVerbCount +
        adverbAdjectiveCount +
        nounNounCount +
        adjectiveAdjectiveCount

        switch wordCount {
            case .two:
                return twoWordCombinations
            case .three:
                return twoWordCombinations * nouns.count
        }
    }

    /// Generates a word pair by selecting a random element from two provided lists.
    ///
    /// - Parameters:
    ///   - list1: The first list of words.
    ///   - list2: The second list of words.
    /// - Returns: A string containing the generated word pair.
    private func generatePair(from list1: [String], and list2: [String]) -> String {
        let word1 = list1.randomElement() ?? ""
        let word2 = list2.randomElement() ?? ""
        return "\(word1)-\(word2)"
    }
}
