package main

import (
	"fmt"
	"os"
	"bytes"
)

func main() {
	process_file(os.Args[1])
}

func process_file(filename string) {
	fmt.Printf("File to use is: %s\n", filename)
	fileBytes, err := os.ReadFile(filename)

	if err != nil {
		panic("could not read file")
	}
	// fmt.Println( )


	x, y, moreTokensFound := bytes.Cut(fileBytes, []byte("\n") )
	fmt.Println(x, y)
	for moreTokensFound == true {
		x, y, moreTokensFound := bytes.Cut(y, []byte("\n") )
		fmt.Println(x, y)
	}

	// show := func(s, sep string) {
	// 	before, after, found := bytes.Cut([]byte(s), []byte(sep))
	// 	fmt.Printf("Cut(%q, %q) = %q, %q, %v\n", s, sep, before, after, found)
	// }
	// show("Gopher", "Go")
	// show("Gopher", "ph")
	// show("Gopher", "er")
	// show("Gopher", "Badger")

	// Cut("Gopher", "Go") = "", "pher", true
	// Cut("Gopher", "ph") = "Go", "er", true
	// Cut("Gopher", "er") = "Goph", "", true
	// Cut("Gopher", "Badger") = "Gopher", "", false

}
