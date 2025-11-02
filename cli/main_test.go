package main

import (
	"testing"
)

func TestQueryPrometheus(t *testing.T) {
	// Test with invalid URL
	_, err := queryPrometheus("http://invalid-url-that-does-not-exist", "up")
	if err == nil {
		t.Error("Expected error for invalid URL, got nil")
	}
}

func TestCarbonCalculation(t *testing.T) {
	// Test carbon calculation logic
	energyWatts := 100.0 // 100 Watts
	hours := 1.0         // 1 hour
	energyKWh := energyWatts * hours / 1000.0
	expectedKWh := 0.1

	if energyKWh != expectedKWh {
		t.Errorf("Expected energy %.4f kWh, got %.4f kWh", expectedKWh, energyKWh)
	}

	carbonGrams := energyKWh * carbonIntensityFactor
	expectedCarbonGrams := 47.5

	if carbonGrams != expectedCarbonGrams {
		t.Errorf("Expected carbon %.2f g, got %.2f g", expectedCarbonGrams, carbonGrams)
	}
}
