//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Testing

@testable import PhraseKit

@Suite("PhraseKit")
struct PhraseKitTests {

  @Test("Default generation skips empty combination types", .timeLimit(.minutes(1)))
  func defaultGenerationSkipsEmptyCombinationTypes() {
    let generator = makeGenerator(
      nouns: [],
      verbs: ["verb"],
      adjectives: [],
      adverbs: ["adverb"]
    )

    #expect(generator.getWordCombinationCount(for: .two) == 1)
    #expect(generator.generatePhrase() == "adverb-verb")
    #expect(generator.generatePhrase() == nil)
  }

  @Test("Two-word exhaustion returns nil instead of retrying forever", .timeLimit(.minutes(1)))
  func twoWordExhaustionReturnsNil() {
    let generator = makeGenerator(
      nouns: ["noun"],
      verbs: [],
      adjectives: ["adjective"],
      adverbs: []
    )

    #expect(generator.generatePhrase(combinationType: .adjectiveNoun) == "adjective-noun")
    #expect(generator.generatePhrase(combinationType: .adjectiveNoun) == nil)
    #expect(generator.getRemainingCombinations(for: .two, combinationType: .adjectiveNoun) == 0)
  }

  @Test("Three-word exhaustion returns nil instead of retrying forever", .timeLimit(.minutes(1)))
  func threeWordExhaustionReturnsNil() {
    let generator = makeGenerator(
      nouns: ["noun"],
      verbs: [],
      adjectives: ["adjective"],
      adverbs: []
    )

    #expect(
      generator.generatePhrase(wordCount: .three, combinationType: .adjectiveNoun)
        == "adjective-noun-noun"
    )
    #expect(generator.generatePhrase(wordCount: .three, combinationType: .adjectiveNoun) == nil)
    #expect(generator.getRemainingCombinations(for: .three, combinationType: .adjectiveNoun) == 0)
  }

  @Test("Generate throws allCombinationsUsed when no phrase remains", .timeLimit(.minutes(1)))
  func generateThrowsWhenNoPhraseRemains() {
    let generator = makeGenerator(
      nouns: [],
      verbs: ["verb"],
      adjectives: [],
      adverbs: ["adverb"]
    )

    #expect(generator.generatePhrase() == "adverb-verb")
    #expect {
      _ = try generator.generate()
    } throws: { error in
      error as? PhraseGenerationError == .allCombinationsUsed
    }
  }

  @Test("Fallback APIs return supplied values after exhaustion", .timeLimit(.minutes(1)))
  func fallbackAPIsReturnSuppliedValuesAfterExhaustion() {
    let defaultGenerator = makeGenerator(
      nouns: [], verbs: ["verb"], adjectives: [], adverbs: ["adverb"])
    #expect(defaultGenerator.generatePhrase() == "adverb-verb")
    #expect(defaultGenerator.generate(withDefault: "default-phrase") == "default-phrase")

    let messageGenerator = makeGenerator(
      nouns: [], verbs: ["verb"], adjectives: [], adverbs: ["adverb"])
    #expect(messageGenerator.generatePhrase() == "adverb-verb")
    #expect(messageGenerator.generate(withMessage: "No more phrases") == "No more phrases")

    let silentGenerator = makeGenerator(
      nouns: [], verbs: ["verb"], adjectives: [], adverbs: ["adverb"])
    #expect(silentGenerator.generatePhrase() == "adverb-verb")
    #expect(silentGenerator.uniquePhrase == "")
  }

  @Test("Reset allows phrase reuse")
  func resetAllowsPhraseReuse() {
    let generator = makeGenerator(
      nouns: [],
      verbs: ["verb"],
      adjectives: [],
      adverbs: ["adverb"]
    )

    #expect(generator.generatePhrase() == "adverb-verb")
    #expect(generator.generatePhrase() == nil)

    generator.resetUsedPairs()

    #expect(generator.generatePhrase() == "adverb-verb")
  }

  @Test("Remaining combinations are scoped to word count and combination type")
  func remainingCombinationsAreScoped() {
    let generator = makeGenerator(
      nouns: ["noun"],
      verbs: [],
      adjectives: ["adjective"],
      adverbs: []
    )

    #expect(generator.generatePhrase(combinationType: .nounNoun) == "noun-noun")
    #expect(generator.getRemainingCombinations(for: .two, combinationType: .adjectiveNoun) == 1)
    #expect(generator.getRemainingCombinations(for: .three, combinationType: .adjectiveNoun) == 1)

    #expect(generator.generatePhrase(combinationType: .adjectiveNoun) == "adjective-noun")
    #expect(generator.getRemainingCombinations(for: .two, combinationType: .adjectiveNoun) == 0)
    #expect(generator.getRemainingCombinations(for: .three, combinationType: .adjectiveNoun) == 1)
  }

  @Test("Default count includes all non-empty built-in combination types")
  func defaultCountIncludesAllNonEmptyBuiltInCombinationTypes() {
    let generator = makeGenerator(
      nouns: ["noun"],
      verbs: ["verb"],
      adjectives: ["adjective"],
      adverbs: ["adverb"]
    )

    #expect(generator.getWordCombinationCount(for: .two) == 6)
    #expect(generator.getWordCombinationCount(for: .three) == 6)
  }

  @Test("Custom loader applies exclusions")
  func customLoaderAppliesExclusions() {
    let generator = PhraseGenerator(
      customLoader: StaticWordLoader(words: ["keep", "blocked"]),
      exclusionList: ["blocked"]
    )

    #expect(generator.getWordCombinationCount(for: .two, combinationType: .custom) == 1)
    #expect(generator.generatePhrase(combinationType: .custom) == "keep-keep")
    #expect(generator.generatePhrase(combinationType: .custom) == nil)
  }

  @Test("Custom loader supports three-word phrases")
  func customLoaderSupportsThreeWordPhrases() {
    let generator = PhraseGenerator(customLoader: StaticWordLoader(words: ["custom"]))

    #expect(generator.getWordCombinationCount(for: .three, combinationType: .custom) == 1)
    #expect(
      generator.generatePhrase(wordCount: .three, combinationType: .custom)
        == "custom-custom-custom"
    )
    #expect(generator.generatePhrase(wordCount: .three, combinationType: .custom) == nil)
  }
}

private func makeGenerator(
  nouns: [String],
  verbs: [String],
  adjectives: [String],
  adverbs: [String]
) -> PhraseGenerator {
  let generator = PhraseGenerator()
  generator.nouns = nouns
  generator.verbs = verbs
  generator.adjectives = adjectives
  generator.adverbs = adverbs
  generator.resetUsedPairs()
  return generator
}

private struct StaticWordLoader: WordLoaderProtocol {
  let words: [String]

  func loadWords() -> [String] {
    words
  }
}
