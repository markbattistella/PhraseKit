<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# PhraseKit

[![Swift Version][Shield1]](https://swiftpackageindex.com/markbattistella/PhraseKit)

[![OS Platforms][Shield2]](https://swiftpackageindex.com/markbattistella/PhraseKit)

[![Licence][Shield3]](https://github.com/markbattistella/PhraseKit/blob/main/LICENSE)

</div>

`PhraseKit` is a Swift package designed to generate random, human-readable phrases composed of various parts of speech, such as adjectives, nouns, verbs, and adverbs. It provides flexible options for generating phrases with different combinations of word types, ensuring that each phrase is unique and grammatically meaningful.

## Why Use This Package?

`PhraseKit` is ideal for a variety of applications where you need to generate random, yet meaningful, phrases. Here are some scenarios where `PhraseKit` could be particularly useful:

- **Random File Names:** Generate unique, descriptive filenames that are easy to recognise and remember, like happy-banana.txt or swift-cloud.png.
- **Usernames or Display Names:** Create random usernames or display names for users, such as brave-panda or running-tiger.
- **Session IDs or Tokens:** Produce human-readable session IDs or tokens that are easier to identify and debug compared to random strings of characters.
- **Creative Writing:** Use PhraseKit as a tool for generating random prompts or ideas for creative writing, brainstorming sessions, or game development.
- **Naming Conventions:** Simplify the process of naming variables, functions, or projects in a way that is both systematic and random.
- **Anywhere You Need Random Phrases:** Whether you’re building an app, writing scripts, or just need random phrases for testing, PhraseKit offers a flexible and easy-to-use solution.

With its ability to customise word lists and combination types, PhraseKit is not just a random generator—it's a tool that adapts to your specific needs.

## Features

- **Random Phrase Generation:** Create phrases with combinations of adjectives, nouns, verbs, and adverbs.
- **Configurable Word Count:** Generate phrases with two or three words.
- **Custom Combination Types:** Specify the types of word combinations (e.g., adjective + noun, verb + noun).
- **Uniqueness Guarantee:** Ensures that each generated phrase is unique and prevents duplicates.
- **Error Handling:** Provides error handling for cases where all possible combinations are exhausted.
- **Extensibility:** Easy to extend and integrate into other projects.

## Installation

### Swift Package Manager

To add `PhraseKit` to your project, use the Swift Package Manager.

1. Open your project in Xcode.
1. Go to `File > Add Packages`.
1. In the search bar, enter the URL of the `PhraseKit` repository:
  
    ```url
    https://github.com/markbattistella/PhraseKit
    ```

1. Click `Add Package`.

## Usage

### Basic Usage

Import the `PhraseKit` package and create an instance of `PhraseGenerator` to start generating phrases.

```swift
import PhraseKit

let generator = PhraseGenerator()

// Generate a random two-word phrase
if let phrase = generator.generatePhrase() {
  print("Generated phrase: \(phrase)")
}

// Generate a random three-word phrase
if let threeWordPhrase = generator.generatePhrase(wordCount: .three) {
  print("Generated three-word phrase: \(threeWordPhrase)")
}
```

### Custom Combination Types

You can specify the type of word combination you'd like to generate:

```swift
let adjectiveNounPhrase = generator.generatePhrase(combinationType: .adjectiveNoun)
print("Adjective + Noun phrase: \(adjectiveNounPhrase ?? "Failed to generate")")

let adverbVerbPhrase = generator.generatePhrase(combinationType: .adverbVerb)
print("Adverb + Verb phrase: \(adverbVerbPhrase ?? "Failed to generate")")
```

#### Handling Exhausted Combinations

`PhraseKit` provides various methods to handle cases where all possible combinations are exhausted:

```swift
// Throw an error if all combinations are exhausted
do {
  let uniquePhrase = try generator.generateUniquePhrase()
  print("Unique phrase: \(uniquePhrase)")
} catch {
  print("Error: \(error)")
}

// Return a default phrase if all combinations are exhausted
let defaultPhrase = generator.generateUniquePhrase(orDefault: "default-phrase")
print("Phrase or default: \(defaultPhrase)")

// Return a custom message if all combinations are exhausted
let customMessagePhrase = generator.generateUniquePhrase(orMessage: "No more phrases available")
print("Phrase or custom message: \(customMessagePhrase)")

// Silent failure: returns an empty string if all combinations are exhausted
let silentPhrase = generator.uniquePhrase
print("Silent phrase: \(silentPhrase.isEmpty ? "No phrase available" : silentPhrase)")
```

## Extensibility

The `PhraseKit` library is designed with extensibility in mind, allowing you to customise and extend its functionality to meet the unique needs of your project. Whether you want to load custom word lists or adjust the logic for generating word combinations, `PhraseKit` provides a flexible framework to do so.

### Custom Word Loading

By default, `PhraseKit` loads word lists (nouns, verbs, adjectives, and adverbs) from JSON files included in the library. However, you can easily override this behaviour by providing your custom word lists. This is especially useful if you need to generate phrases using a specific set of words or if your application requires different or additional parts of speech.

#### Using a Custom Word Loader

To load custom word lists, implement the `WordLoaderProtocol` in your own class and provide the custom words through this loader. Here’s an example of how to do this:

```swift
import PhraseKit

// Implement the WordLoaderProtocol
class MyCustomWordLoader: WordLoaderProtocol {
  func loadWords() -> [String] {
    // Load your custom words from a source, e.g., a local file, database, or API
    return ["customWord1", "customWord2", "customWord3"]
  }
}

// Initialize PhraseGenerator with the custom loader
let customLoader = MyCustomWordLoader()
let generator = PhraseGenerator(customLoader: customLoader)

// Generate a phrase using the custom words
if let phrase = generator.generatePhrase() {
  print("Generated phrase: \(phrase)")
}
```

In this example, the `PhraseGenerator` will exclusively use the custom words provided by `MyCustomWordLoader` for phrase generation, ignoring the default word lists that are otherwise loaded from JSON files.

### Extending Word Combinations

The `PhraseGenerator` class supports various types of word combinations by default, such as adjective-noun or verb-noun. However, if your project requires a different type of combination or you want to include additional logic, you can extend the `PhraseGenerator` or implement your custom logic in your word loader.

#### Example: Custom Combination Logic

You might want to introduce new logic that pairs words based on a specific rule or pattern. This can be done by extending the `CombinationType` enum or by adding custom logic to the generateWordPair method in a subclass of `PhraseGenerator`.

```swift
import PhraseKit

class CustomPhraseGenerator: PhraseGenerator {
  
  override func generateWordPair(combinationType: CombinationType? = nil) -> String? {
    // Custom logic for generating word pairs
    let customType = combinationType ?? .adjectiveNoun
    
    switch customType {
      case .adjectiveNoun:
        return generatePair(from: adjectives, and: nouns)
      // Add your custom combination logic here
      default:
        return super.generateWordPair(combinationType: combinationType)
    }
  }
}

let customGenerator = CustomPhraseGenerator()
if let phrase = customGenerator.generatePhrase() {
  print("Custom generated phrase: \(phrase)")
}
```

This example demonstrates how you can extend or modify the combination logic to suit specific requirements, while still leveraging the underlying structure of `PhraseKit`.

## Testing

`PhraseKit` comes with a comprehensive test suite to ensure reliability and correctness. The tests cover various scenarios, including default phrase generation, specific word combinations, and error handling.

To run the tests, use:

```bash
swift test
```

## Contributing

Contributions are welcome! If you have suggestions or improvements, please fork the repository and submit a pull request.

## License

`PhraseKit` is released under the MIT license. See [LICENSE](https://github.com/markbattistella/PhraseKit/blob/main/LICENSE) for details.

[Shield1]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FPhraseKit%2Fbadge%3Ftype%3Dswift-versions

[Shield2]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FPhraseKit%2Fbadge%3Ftype%3Dplatforms

[Shield3]: https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat
