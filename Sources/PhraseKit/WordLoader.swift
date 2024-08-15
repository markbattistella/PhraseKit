//
// Project: PhraseKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// `WordLoader` is responsible for loading word lists from JSON files.
///
/// This class provides functionality to load words from JSON files within the app bundle.
/// It also conforms to the `WordLoaderProtocol` to ensure compatibility with custom loaders.
internal class WordLoader: WordLoaderProtocol {
    
    /// Loads words from a specified JSON file.
    ///
    /// This method attempts to locate and load a JSON file from the module's bundle. The file 
    /// is expected to contain an array of strings. If the file cannot be found or parsed, an
    /// empty array is returned.
    ///
    /// - Parameter fileName: The name of the JSON file to load (without extension).
    /// - Returns: An array of strings containing the words loaded from the file, or an empty 
    /// array if the file cannot be found or parsed.
    static func loadWords(from fileName: String) -> [String] {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let words = try JSONDecoder().decode([String].self, from: data)
            return words
        } catch {
            return []
        }
    }
    
    /// Conforms to `WordLoaderProtocol` by loading words from a specified JSON file.
    ///
    /// This method loads words using the `loadWords(from:)` method, with "default" as the file 
    /// name. It is primarily used to demonstrate protocol conformance.
    ///
    /// - Returns: An array of strings containing the words loaded from the "default" JSON file.
    func loadWords() -> [String] {
        return WordLoader.loadWords(from: "default")
    }
}

/// `WordLoaderProtocol` defines the requirements for a word loader used in phrase generation.
///
/// Any custom word loader must conform to this protocol, ensuring that it provides a method
/// to load an array of words.
public protocol WordLoaderProtocol {
    
    /// Loads words for use in phrase generation.
    ///
    /// This method should be implemented by any custom word loader to provide a list of words
    /// that can be used in generating phrases.
    ///
    /// - Returns: An array of strings containing the words to be used in phrase generation.
    func loadWords() -> [String]
}
