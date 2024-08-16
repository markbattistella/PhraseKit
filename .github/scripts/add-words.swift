import Foundation

func main() {

    if let body = ProcessInfo.processInfo.environment["GH_BODY_JSON"] {
        print("body:", body)
    }
}

main()
