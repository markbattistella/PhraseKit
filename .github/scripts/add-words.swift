import Foundation

func main() {

    if let wordList = ProcessInfo.processInfo.environment["WORDS"] {
        print("word:", wordList)
    }

    if let pos = ProcessInfo.processInfo.environment["POS"] {
        print("pos:", pos)
    }
}

main()
