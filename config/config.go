package config

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
)

// EnvSetup - load env from json
func EnvSetup() error {
	jsonFile, err := os.Open("config/env.json")
	if err != nil {
		return fmt.Errorf("failed to open json file: %w", err)
	}

	rawJSON, err := io.ReadAll(jsonFile)
	if err != nil {
		return fmt.Errorf("failed to read json file: %w", err)
	}

	var config Config
	err = json.Unmarshal(rawJSON, &config)
	if err != nil {
		return fmt.Errorf("failed to unmarshal env.json: %w", err)
	}

	env := os.Getenv("GO_ENV")
	if env == "" {
		env = "development" // Default to development if not set
	}

	// Select the appropriate configuration
	var envVars envkey
	switch env {
	case "development":
		envVars = config.Development
	case "production":
		envVars = config.Production
	default:
		return fmt.Errorf("unknown environment: %s", env)
	}

	for key, value := range envVars {
		err := os.Setenv(key, value)
		if err != nil {
			return fmt.Errorf("failed to set environment variable %s: %w", key, err)
		}
		fmt.Printf("key  %s : set to %s environment variable \n", key, value)

	}

	defer jsonFile.Close()
	return nil
}
