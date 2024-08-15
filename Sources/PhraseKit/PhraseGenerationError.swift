//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// `PhraseGenerationError` is an enum representing possible errors that can occur during
/// phrase generation.
public enum PhraseGenerationError: Error, LocalizedError {

    /// Indicates that all possible word combinations have been used.
    case allCombinationsUsed

    /// A description of the error, suitable for displaying to the user.
    public var errorDescription: String? {
        switch self {
            case .allCombinationsUsed:
                return "All possible word combinations have been used."
        }
    }
}
