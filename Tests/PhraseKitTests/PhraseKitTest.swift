//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import XCTest
@testable import PhraseKit

/// `PhraseKitTests` is a test suite for testing the `PhraseGenerator` class in the PhraseKit
/// package.
final class PhraseKitTests: XCTestCase {

    /// The `PhraseGenerator` instance used in each test.
    var generator: PhraseGenerator!

    /// Sets up the test environment before each test method is invoked.
    ///
    /// This method is called before each test method in the class is called. It initializes
    /// the `PhraseGenerator` instance and limits the word lists to a small subset to ensure
    /// that combinations can be exhausted within the tests.
    override func setUp() {
        super.setUp()
        generator = PhraseGenerator()

        let wordLimit = 20

        // Limit the word lists to a small subset to ensure combinations can be exhausted
        generator.nouns = Array(generator.nouns.prefix(wordLimit))
        generator.verbs = Array(generator.verbs.prefix(wordLimit))
        generator.adjectives = Array(generator.adjectives.prefix(wordLimit))
        generator.adverbs = Array(generator.adverbs.prefix(wordLimit))
    }

    /// Tears down the test environment after each test method is invoked.
    ///
    /// This method is called after each test method in the class is called. It deallocates the
    /// `PhraseGenerator` instance to ensure a clean state for the next test.
    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// Tests the default two-word phrase generation.
    ///
    /// This test ensures that the `generatePhrase()` method correctly generates a non-empty
    /// phrase consisting of two words.
    func testGenerateTwoWordPhraseDefault() {
        if let phrase = generator.generatePhrase() {
            print("Generated phrase: \(phrase)")
            XCTAssertFalse(
                phrase.isEmpty,
                "Generated phrase should not be empty"
            )
            XCTAssertEqual(
                phrase.split(separator: "-").count,
                2,
                "Phrase should contain two words"
            )
        } else {
            XCTFail("Failed to generate a two-word phrase")
        }
    }

    /// Tests the three-word phrase generation.
    ///
    /// This test ensures that the `generatePhrase(wordCount: .three)` method correctly generates
    /// a non-empty phrase consisting of three words.
    func testGenerateThreeWordPhrase() {
        if let phrase = generator.generatePhrase(wordCount: .three) {
            print("Generated phrase: \(phrase)")
            XCTAssertFalse(
                phrase.isEmpty,
                "Generated phrase should not be empty"
            )
            XCTAssertEqual(
                phrase.split(separator: "-").count,
                3,
                "Phrase should contain three words"
            )
        } else {
            XCTFail("Failed to generate a three-word phrase")
        }
    }

    /// Tests generating a phrase with a specific combination type (Adjective + Noun).
    ///
    /// This test ensures that the `generatePhrase(combinationType: .adjectiveNoun)` method
    /// correctly generates a non-empty phrase consisting of an adjective and a noun.
    func testGenerateAdjectiveNounPhrase() {
        if let phrase = generator.generatePhrase(combinationType: .adjectiveNoun) {
            print("Generated phrase: \(phrase)")
            XCTAssertFalse(
                phrase.isEmpty,
                "Generated phrase should not be empty"
            )
            XCTAssertEqual(
                phrase.split(separator: "-").count,
                2,
                "Phrase should contain two words"
            )
        } else {
            XCTFail("Failed to generate an Adjective + Noun phrase")
        }
    }

    /// Tests generating a phrase with a specific combination type (Adverb + Verb).
    ///
    /// This test ensures that the `generatePhrase(combinationType: .adverbVerb)` method correctly
    /// generates a non-empty phrase consisting of an adverb and a verb.
    func testGenerateAdverbVerbPhrase() {
        if let phrase = generator.generatePhrase(combinationType: .adverbVerb) {
            print("Generated phrase: \(phrase)")
            XCTAssertFalse(
                phrase.isEmpty,
                "Generated phrase should not be empty"
            )
            XCTAssertEqual(
                phrase.split(separator: "-").count,
                2,
                "Phrase should contain two words"
            )
        } else {
            XCTFail("Failed to generate an Adverb + Verb phrase")
        }
    }

    /// Tests generating a three-word phrase with a specific combination type (Verb + Noun).
    ///
    /// This test ensures that the `generatePhrase(wordCount: .three, combinationType: .verbNoun)`
    /// method correctly generates a non-empty phrase consisting of three words, with the
    /// specified combination type.
    func testGenerateThreeWordPhraseWithType() {
        if let phrase = generator.generatePhrase(wordCount: .three, combinationType: .verbNoun) {
            print("Generated phrase: \(phrase)")
            XCTAssertFalse(
                phrase.isEmpty,
                "Generated phrase should not be empty"
            )
            XCTAssertEqual(
                phrase.split(separator: "-").count,
                3,
                "Phrase should contain three words"
            )
        } else {
            XCTFail("Failed to generate a three-word phrase with Verb + Noun combination")
        }
    }

    /// Tests that all combinations used up throws an error.
    ///
    /// This test ensures that the `generateUniquePhrase()` method correctly throws a
    /// `PhraseGenerationError.allCombinationsUsed` error when all possible combinations have
    /// been exhausted.
    func testAllCombinationsUsedError() {
        do {
            for _ in 0..<1000 {
                _ = try generator.generate()
            }
            XCTFail("Expected to throw an error, but it did not.")
        } catch PhraseGenerationError.allCombinationsUsed {
            print("Correctly threw all combinations used error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Tests that a default phrase is returned when combinations are exhausted.
    ///
    /// This test ensures that the `generateUniquePhrase(orDefault:)` method returns a specified
    /// default phrase when all possible combinations have been exhausted.
    func testGeneratePhraseWithDefaultOnFailure() {
        for _ in 0..<1000 {
            _ = generator.generatePhrase() ?? "default-phrase"
        }

        let phrase = generator.generate(withDefault: "default-phrase")
        XCTAssertEqual(
            phrase,
            "default-phrase",
            "Should return the default phrase when combinations are exhausted"
        )
    }

    /// Tests that a custom message is returned when combinations are exhausted.
    ///
    /// This test ensures that the `generateUniquePhrase(orMessage:)` method returns a
    /// specified custom message when all possible combinations have been exhausted.
    func testGeneratePhraseWithCustomMessageOnFailure() {
        for _ in 0..<1000 {
            _ = generator.generatePhrase() ?? "custom-message"
        }

        let phrase = generator.generate(withMessage: "No more phrases available")
        XCTAssertEqual(
            phrase,
            "No more phrases available",
            "Should return the custom message when combinations are exhausted"
        )
    }
    
    /// Tests silent failure mode (empty string).
    ///
    /// This test ensures that the `uniquePhrase` computed property returns an empty string when
    /// all possible combinations have been exhausted, without throwing an error or returning
    /// a custom message.
    func testSilentFailure() {
        for _ in 0..<1000 {
            _ = generator.generatePhrase() ?? ""
        }

        let phrase = generator.uniquePhrase
        XCTAssertEqual(
            phrase,
            "",
            "Should return an empty string when combinations are exhausted"
        )
    }
}
