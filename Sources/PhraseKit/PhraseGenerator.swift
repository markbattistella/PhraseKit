//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// `PhraseGenerator` is a class designed to generate random, human-readable phrases
/// composed of various parts of speech, such as adjectives, nouns, verbs, and adverbs.
@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
open class PhraseGenerator {

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
  public enum CombinationType: CaseIterable, Sendable {
    case adjectiveNoun
    case verbNoun
    case adverbVerb
    case adverbAdjective
    case nounNoun
    case adjectiveAdjective
    case custom
  }

  /// The number of words in the generated phrase.
  public enum WordCount: Int, Sendable {
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
      self.applyExclusionList()
    }
  }
}

// MARK: - Public methods

extension PhraseGenerator {

  /// Generates a random phrase with the specified word count and combination type.
  ///
  /// - Parameters:
  ///   - wordCount: The number of words in the phrase (default is two).
  ///   - combinationType: The specific type of word combination to generate (optional).
  /// - Returns: A string containing the generated phrase, or `nil` if no valid phrase could
  /// be generated.
  public func generatePhrase(
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
  public func generate() throws(PhraseGenerationError) -> String {
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
  public func generate(withDefault defaultPhrase: String) -> String {
    return generatePhrase() ?? defaultPhrase
  }

  /// Generates a unique phrase or returns a custom message if all combinations are exhausted.
  ///
  /// - Parameter message: The message to return if no more unique phrases can be generated.
  /// - Returns: A unique phrase string or the provided custom message.
  public func generate(withMessage message: String = "All combinations used") -> String {
    return generatePhrase() ?? message
  }

  /// A computed property that generates a unique phrase silently, returning an empty string
  /// if all combinations are exhausted.
  public var uniquePhrase: String {
    return generatePhrase() ?? ""
  }

  /// Returns the count of possible word combinations for a given word count and combination type.
  ///
  /// - Parameters:
  ///   - wordCount: The number of words in the phrase.
  ///   - combinationType: The type of word combination.
  /// - Returns: The number of possible combinations.
  public func getWordCombinationCount(
    for wordCount: WordCount,
    combinationType: CombinationType? = nil
  ) -> Int {
    guard let combinationType else {
      return CombinationType.allCases.reduce(0) { total, type in
        total.addingClamping(calculateCombinationCount(for: wordCount, combinationType: type))
      }
    }

    return calculateCombinationCount(for: wordCount, combinationType: combinationType)
  }

  /// Returns the number of remaining combinations for a given word count and combination type.
  ///
  /// - Parameters:
  ///   - wordCount: The number of words in the phrase.
  ///   - combinationType: The type of word combination.
  /// - Returns: The number of remaining combinations.
  public func getRemainingCombinations(
    for wordCount: WordCount,
    combinationType: CombinationType? = nil
  ) -> Int {
    let totalCombinations = getWordCombinationCount(
      for: wordCount,
      combinationType: combinationType
    )
    let usedCombinations = usedPhraseCount(
      for: wordCount,
      combinationType: combinationType
    )
    return max(totalCombinations - usedCombinations, 0)
  }

  /// Resets the list of used word pairs.
  public func resetUsedPairs() {
    usedPairs.removeAll()
  }
}

// MARK: - Private Methods

extension PhraseGenerator {

  /// The number of random attempts made before falling back to deterministic search.
  private var randomGenerationAttemptLimit: Int { 100 }

  /// Applies the exclusion list to all word lists, removing any excluded words and updates
  /// the lists.
  private func applyExclusionList() {
    let excludedWords = Set(exclusionList)
    nouns = nouns.filter { !excludedWords.contains($0) }
    verbs = verbs.filter { !excludedWords.contains($0) }
    adjectives = adjectives.filter { !excludedWords.contains($0) }
    adverbs = adverbs.filter { !excludedWords.contains($0) }
    customList = customList.filter { !excludedWords.contains($0) }
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
    let lists = wordLists(for: combinationType)

    guard !lists.first.isEmpty && !lists.second.isEmpty else { return 0 }

    let twoWordCombinations = lists.first.count.multipliedClamping(by: lists.second.count)
    guard wordCount == .three else { return twoWordCombinations }

    let thirdWords = thirdWordList(for: combinationType)
    guard !thirdWords.isEmpty else { return 0 }
    return twoWordCombinations.multipliedClamping(by: thirdWords.count)
  }

  /// Generates a two-word phrase based on the specified combination type.
  ///
  /// - Parameter combinationType: The type of word combination.
  /// - Returns: A generated two-word phrase as a string, or nil if no unique phrase can be
  /// generated.
  private func generateTwoWordPhrase(combinationType: CombinationType? = nil) -> String? {
    let types = availableCombinationTypes(for: .two, requested: combinationType)

    guard
      let pair = randomUnusedTwoWordPhrase(from: types)
        ?? firstUnusedTwoWordPhrase(from: types)
    else {
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
    let types = availableCombinationTypes(for: .three, requested: combinationType)

    guard
      let phrase = randomUnusedThreeWordPhrase(from: types)
        ?? firstUnusedThreeWordPhrase(from: types)
    else {
      return nil
    }

    usedPairs.insert(phrase)
    return phrase
  }

  /// Generates a pair of words based on the specified combination type.
  ///
  /// - Parameter combinationType: The type of word combination.
  /// - Returns: A generated word pair as a string.
  private func generatePair(from combinationType: CombinationType) -> String? {
    let lists = wordLists(for: combinationType)
    guard
      let word1 = lists.first.randomElement(),
      let word2 = lists.second.randomElement()
    else {
      return nil
    }

    return "\(word1)-\(word2)"
  }

  /// Returns combination types that can produce at least one phrase.
  private func availableCombinationTypes(
    for wordCount: WordCount,
    requested combinationType: CombinationType?
  ) -> [CombinationType] {
    if let combinationType {
      return calculateCombinationCount(for: wordCount, combinationType: combinationType) > 0
        ? [combinationType]
        : []
    }

    return CombinationType.allCases.filter {
      calculateCombinationCount(for: wordCount, combinationType: $0) > 0
    }
  }

  /// Returns the first and second word lists for a combination type.
  private func wordLists(for combinationType: CombinationType) -> (
    first: [String], second: [String]
  ) {
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
  }

  /// Returns the third word list used by three-word generation.
  private func thirdWordList(for combinationType: CombinationType) -> [String] {
    combinationType == .custom ? customList : nouns
  }

  /// Counts used phrases that belong to a word count and optional combination type.
  private func usedPhraseCount(
    for wordCount: WordCount,
    combinationType: CombinationType?
  ) -> Int {
    let types = availableCombinationTypes(for: wordCount, requested: combinationType)

    return usedPairs.reduce(0) { count, phrase in
      isPhrase(phrase, wordCount: wordCount, inAny: types) ? count + 1 : count
    }
  }

  /// Returns whether a phrase can be produced by any of the supplied combination types.
  private func isPhrase(
    _ phrase: String,
    wordCount: WordCount,
    inAny types: [CombinationType]
  ) -> Bool {
    types.contains { isPhrase(phrase, wordCount: wordCount, combinationType: $0) }
  }

  /// Returns whether a phrase can be produced by a specific combination type.
  private func isPhrase(
    _ phrase: String,
    wordCount: WordCount,
    combinationType: CombinationType
  ) -> Bool {
    let parts = phrase.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
    guard parts.count == wordCount.rawValue else { return false }

    let lists = wordLists(for: combinationType)
    guard lists.first.contains(parts[0]), lists.second.contains(parts[1]) else {
      return false
    }

    guard wordCount == .three else { return true }
    return thirdWordList(for: combinationType).contains(parts[2])
  }

  /// Attempts to find an unused two-word phrase by random sampling.
  private func randomUnusedTwoWordPhrase(from types: [CombinationType]) -> String? {
    guard !types.isEmpty else { return nil }

    for _ in 0..<randomGenerationAttemptLimit {
      guard
        let type = types.randomElement(),
        let pair = generatePair(from: type),
        !usedPairs.contains(pair)
      else {
        continue
      }

      return pair
    }

    return nil
  }

  /// Finds the first unused two-word phrase deterministically.
  private func firstUnusedTwoWordPhrase(from types: [CombinationType]) -> String? {
    for type in types {
      let lists = wordLists(for: type)

      for firstWord in lists.first {
        for secondWord in lists.second {
          let pair = "\(firstWord)-\(secondWord)"
          if !usedPairs.contains(pair) {
            return pair
          }
        }
      }
    }

    return nil
  }

  /// Attempts to find an unused three-word phrase by random sampling.
  private func randomUnusedThreeWordPhrase(from types: [CombinationType]) -> String? {
    guard !types.isEmpty else { return nil }

    for _ in 0..<randomGenerationAttemptLimit {
      guard
        let type = types.randomElement(),
        let pair = generatePair(from: type),
        let thirdWord = thirdWordList(for: type).randomElement()
      else {
        continue
      }

      let phrase = "\(pair)-\(thirdWord)"
      if !usedPairs.contains(phrase) {
        return phrase
      }
    }

    return nil
  }

  /// Finds the first unused three-word phrase deterministically.
  private func firstUnusedThreeWordPhrase(from types: [CombinationType]) -> String? {
    for type in types {
      let lists = wordLists(for: type)
      let thirdWords = thirdWordList(for: type)

      for firstWord in lists.first {
        for secondWord in lists.second {
          for thirdWord in thirdWords {
            let phrase = "\(firstWord)-\(secondWord)-\(thirdWord)"
            if !usedPairs.contains(phrase) {
              return phrase
            }
          }
        }
      }
    }

    return nil
  }

  /// Clears the internal word lists, setting them to empty arrays.
  private func clearInternalWordLists() {
    self.nouns = []
    self.verbs = []
    self.adjectives = []
    self.adverbs = []
  }
}

extension Int {

  /// Adds two integers, clamping to `Int.max` if the result overflows.
  fileprivate func addingClamping(_ other: Int) -> Int {
    let result = addingReportingOverflow(other)
    return result.overflow ? Int.max : result.partialValue
  }

  /// Multiplies two integers, clamping to `Int.max` if the result overflows.
  fileprivate func multipliedClamping(by other: Int) -> Int {
    let result = multipliedReportingOverflow(by: other)
    return result.overflow ? Int.max : result.partialValue
  }
}
