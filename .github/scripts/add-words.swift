import Foundation

func main() {

    if let body = ProcessInfo.processInfo.environment["GH_BODY"] {
        print("body:", body)
    }

    if let wordList = ProcessInfo.processInfo.environment["WORDS"] {
        print("word:", wordList)
    }

    if let pos = ProcessInfo.processInfo.environment["POS"] {
        print("pos:", pos)
    }
}

main()
