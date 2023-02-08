package main

import (
	"bytes"
	"fmt"
	"os"
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
	var calorieCount int = 0
	var mostCalories int = 0
	var moreTokensFound bool = true
	for moreTokensFound == true {
		x, y, moreFound := bytes.Cut(fileBytes, []byte("\n"))
		i, _ := strconv.Atoi(string(x))
		calorieCount += i
		// fmt.Println(calorieCount)
		if len(x) == 0 {
			if calorieCount > mostCalories {
				mostCalories = calorieCount
			}
			calorieCount = 0
		}
		fileBytes = y
		moreTokensFound = moreFound
	}
	fmt.Println(mostCalories)
}
