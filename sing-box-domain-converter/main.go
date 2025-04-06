package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type RuleSet struct {
	Version int    `json:"version"`
	Rules   []Rule `json:"rules"`
}

type Rule struct {
	DomainSuffix []string `json:"domain_suffix"`
}

const (
	CurrentVersion = 3
)

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Usage: %s <input_file> [output_file]\n", filepath.Base(os.Args[0]))
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := getOutputFilename(inputFile)

	if len(os.Args) > 2 {
		outputFile = os.Args[2]
	}

	if err := convertDomainsToJSON(inputFile, outputFile); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Successfully converted %s to %s\n", inputFile, outputFile)
}

func convertDomainsToJSON(inputFile, outputFile string) error {
	data, err := os.ReadFile(inputFile)
	if err != nil {
		return fmt.Errorf("Reading file: %w", err)
	}

	domains := parseDomains(string(data))
	if len(domains) == 0 {
		return fmt.Errorf("No valid domains found in input file")
	}

	ruleSet := RuleSet{
		Version: CurrentVersion,
		Rules: []Rule{
			{
				DomainSuffix: domains,
			},
		},
	}

	jsonData, err := json.MarshalIndent(ruleSet, "", "    ")
	if err != nil {
		return fmt.Errorf("Generating JSON: %w", err)
	}

	if err := os.WriteFile(outputFile, jsonData, 0644); err != nil {
		return fmt.Errorf("Writing file: %w", err)
	}

	return nil
}

func parseDomains(str string) []string {
	lines := strings.Split(strings.TrimSpace(str), "\n")
	domains := make([]string, 0, len(lines))

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Remove any trailing comments
		if commentIndex := strings.Index(line, "#"); commentIndex != -1 {
			line = strings.TrimSpace(line[:commentIndex])
		}

		// Remove any protocol prefixes
		line = strings.TrimPrefix(line, "http://")
		line = strings.TrimPrefix(line, "https://")
		line = strings.TrimPrefix(line, "www.")

		// Remove port numbers if present
		if portIndex := strings.Index(line, ":"); portIndex != -1 {
			line = line[:portIndex]
		}

		// Remove paths if present
		if pathIndex := strings.Index(line, "/"); pathIndex != -1 {
			line = line[:pathIndex]
		}

		// Validate the domain contains at least one dot (but not at start/end)
		if len(line) == 0 || line[0] == '.' || line[len(line)-1] == '.' || !strings.Contains(line, ".") {
			continue
		}

		domains = append(domains, line)
	}

	return domains
}

func getOutputFilename(inputFile string) string {
	ext := filepath.Ext(inputFile)
	if ext != "" {
		return inputFile[:len(inputFile)-len(ext)] + ".json"
	}
	return inputFile + ".json"
}
