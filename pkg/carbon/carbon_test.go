package carbon

import (
	"testing"
)

func TestCalculateCO2FromEnergy(t *testing.T) {
	tests := []struct {
		name            string
		energyKWh       float64
		carbonIntensity float64
		expected        float64
	}{
		{"default intensity", 1.0, 0, 475.0},
		{"custom intensity", 1.0, 300.0, 300.0},
		{"zero energy", 0.0, 475.0, 0.0},
		{"fractional energy", 0.5, 400.0, 200.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateCO2FromEnergy(tt.energyKWh, tt.carbonIntensity)
			if result != tt.expected {
				t.Errorf("expected %f, got %f", tt.expected, result)
			}
		})
	}
}

func TestEstimatePerInference(t *testing.T) {
	tests := []struct {
		name          string
		totalCO2Grams float64
		requestCount  int64
		expected      float64
	}{
		{"normal case", 100.0, 1000, 0.1},
		{"zero requests", 100.0, 0, 0.0},
		{"single request", 10.0, 1, 10.0},
		{"fractional result", 1.0, 3, 0.3333333333333333},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := EstimatePerInference(tt.totalCO2Grams, tt.requestCount)
			if result != tt.expected {
				t.Errorf("expected %f, got %f", tt.expected, result)
			}
		})
	}
}
