import Foundation

func main() {

    if let body = ProcessInfo.processInfo.environment["GH_BODY"] {
        print("body:", body)
    }
}

main()
