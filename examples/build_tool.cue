import "tool/cli"

greeting: string @tag(tag1)
farewell: string @tag(tag2)

command: build: out: cli.Print & {text: "\(greeting)! \(farewell)."}