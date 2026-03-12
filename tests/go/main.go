package main

import (
	"fmt"
	"strings"
)

type Greeter struct {
	Prefix string
}

func (g Greeter) Message(name string) string {
	return fmt.Sprintf("%s, %s!", g.Prefix, strings.TrimSpace(name))
}

func buildMessages(names []string, g Greeter) ([]string, error) {
	if len(names) == 0 {
		return nil, fmt.Errorf("no names provided")
	}
	out := make([]string, 0, len(names))
	for _, n := range names {
		out = append(out, g.Message(n))
	}
	return out, nil
}

func main() {
	messages, err := buildMessages([]string{"Ada", "Grace", "Linus"}, Greeter{Prefix: "Hello from Go"})
	if err != nil {
		panic(err)
	}
	for _, m := range messages {
		fmt.Println(m)
	}

	// Uncomment for diagnostics test:
	// fmt.Println(unknownValue)
}
