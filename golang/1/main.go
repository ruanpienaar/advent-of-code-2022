package main

import (
	"bytes"
	"fmt"
	"os"
	"sort"
	"strconv"
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
	var topX []int
	var calorieCount int = 0
	var moreTokensFound bool = true
	for moreTokensFound == true {
		x, y, moreFound := bytes.Cut(fileBytes, []byte("\n"))
		i, _ := strconv.Atoi(string(x))
		calorieCount += i
		if len(x) == 0 {
			topX = append(topX, calorieCount)
			fmt.Println(topX)
			calorieCount = 0
		}
		fileBytes = y
		moreTokensFound = moreFound
	}
	sort.Ints(topX)
	topThree := topX[len(topX)-3] + topX[len(topX)-2] + topX[len(topX)-1]
	fmt.Println(topThree)
}
