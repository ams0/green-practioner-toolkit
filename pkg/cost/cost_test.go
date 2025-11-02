package cost

import (
	"testing"
)

func TestCalculateCostPerToken(t *testing.T) {
	tests := []struct {
		name       string
		totalCost  float64
		tokenCount int64
		expected   float64
	}{
		{"normal case", 1.0, 1000, 0.001},
		{"zero tokens", 1.0, 0, 0.0},
		{"zero cost", 0.0, 1000, 0.0},
		{"fractional cost", 0.5, 200, 0.0025},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateCostPerToken(tt.totalCost, tt.tokenCount)
			if result != tt.expected {
				t.Errorf("expected %f, got %f", tt.expected, result)
			}
		})
	}
}

func TestCalculatePer1KTokens(t *testing.T) {
	tests := []struct {
		name       string
		totalCost  float64
		tokenCount int64
		expected   float64
	}{
		{"normal case", 1.0, 1000, 1.0},
		{"large token count", 10.0, 1000000, 0.01},
		{"zero tokens", 1.0, 0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculatePer1KTokens(tt.totalCost, tt.tokenCount)
			if result != tt.expected {
				t.Errorf("expected %f, got %f", tt.expected, result)
			}
		})
	}
}
