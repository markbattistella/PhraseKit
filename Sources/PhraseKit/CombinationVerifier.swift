//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

#if canImport(NaturalLanguage)
import Foundation
import NaturalLanguage

/// `CombinationVerifier` is responsible for verifying that generated word combinations have 
/// different parts of speech, ensuring that the generated phrases are meaningful and adhere to
/// grammatical rules.
internal class CombinationVerifier {

    /// Verifies that the combination has distinct parts of speech.
    ///
    /// - Parameter combination: The word combination to verify, in the format "word1-word2".
    /// - Returns: A boolean indicating whether the combination has distinct parts of speech.
    static func verifyCombination(_ combination: String) -> Bool {
        let words = combination.split(separator: "-").map { String($0) }

        guard words.count == 2 || words.count == 3 else { return false }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = combination

        var posTags: [NLTag] = []

        for word in words {
            let range = combination.range(of: word)!
            let (tag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lexicalClass)
            if let posTag = tag {
                posTags.append(posTag)
            }
        }

        if words.count == 2 {
            return posTags.count == 2 && posTags[0] != posTags[1]
        } else {
            return posTags.count == 3 && posTags[0] != posTags[1] && posTags[1] != posTags[2]
        }
    }
}
#endif
