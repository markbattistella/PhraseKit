//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// `WordLoader` is responsible for loading word lists from JSON files.
///
/// This class provides functionality to load words from JSON files located within the app bundle.
/// It adheres to the `WordLoaderProtocol`, ensuring compatibility with other custom loaders that
/// conform to this protocol. The primary purpose of this class is to facilitate phrase generation
/// by providing a set of words loaded from predefined JSON files.
internal class WordLoader: WordLoaderProtocol {
    
    /// Loads words from a specified JSON file.
    ///
    /// This method attempts to locate and load a JSON file from the module's bundle. The JSON file
    /// should contain an array of strings categorized under keys such as "safe". If the file cannot
    /// be found or if parsing fails due to format issues or data corruption, an empty array is
    /// returned.
    ///
    /// - Parameter fileName: The name of the JSON file to load (without the file extension).
    /// - Returns: An array of strings containing the "safe" words loaded from the file. If the file
    ///   is missing or an error occurs during loading/parsing, an empty array is returned.
    static func loadWords(from fileName: String) -> [String] {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
            
            // Returns an empty array if the file cannot be found in the bundle
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let words = try JSONDecoder().decode(WordLists.self, from: data)
            
            // Returns the "safe" words array from the decoded data
            return words.safe
            
        } catch {
            
            // Returns an empty array if an error occurs during data loading or decoding
            return []
        }
    }
    
    /// Conforms to `WordLoaderProtocol` by loading words from a default JSON file.
    ///
    /// This method demonstrates protocol conformance by loading words using the `loadWords(from:)`
    /// method with the hardcoded file name "default". This can be useful as a fallback or initial
    /// implementation when no specific filename is provided.
    ///
    /// - Returns: An array of strings containing the words loaded from the "default" JSON file,
    ///   or an empty array if the file cannot be found or parsed.
    func loadWords() -> [String] {
        return WordLoader.loadWords(from: "default")
    }
}

/// `WordLoaderProtocol` defines the requirements for a word loader used in phrase generation.
///
/// Conforming types must implement the `loadWords()` method to provide an array of words that
/// can be utilized in generating phrases. This protocol standardizes the interface for word
/// loading across different implementations, allowing flexibility in the source of words.
public protocol WordLoaderProtocol {
    
    /// Loads words for use in phrase generation.
    ///
    /// Implementers should provide a list of words that can be used in the phrase generation
    /// process. This ensures consistency and reliability across different word loaders.
    ///
    /// - Returns: An array of strings containing the words to be used in phrase generation.
    func loadWords() -> [String]
}

/// `WordLists` represents the structure of the JSON model used by `WordLoader`.
///
/// This struct conforms to the `Decodable` protocol, allowing it to be directly initialized
/// from JSON data. It contains three categories of word lists:
/// - `pending`: Words that are awaiting approval or further processing.
/// - `safe`: Words that are approved and safe for use.
/// - `incompatible`: Words that are deemed unsuitable or incompatible for use.
internal struct WordLists: Decodable {
    let pending: [String]
    let safe: [String]
    let incompatible: [String]
}
