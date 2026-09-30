import Foundation

struct SpectrumPoint {
    /// Hz
    let frequency: Double
    let magnitude: Double
}

/// Generated accelerometer FFT spectra, standing in until cogitator sends real FFT data
enum PlaceholderSpectrum {
    static let pointCount = 100
    /// Hz between points; with `pointCount` covers 0–50 Hz
    static let frequencyStep = 0.5

    /// Balancer IMU: motor vibration at 8 Hz with harmonics, structural resonance at 35 Hz
    static func balancer() -> [SpectrumPoint] {
        spectrum { frequency in
            exp(-frequency / 30) * Double.random(in: 0.05..<0.08)
                + peak(at: 8, height: 0.6, width: 2, frequency: frequency)
                + peak(at: 16, height: 0.3, width: 3, frequency: frequency)
                + peak(at: 24, height: 0.15, width: 4, frequency: frequency)
                + peak(at: 35, height: 0.2, width: 2.5, frequency: frequency)
        }
    }

    /// OAK-D Pro W IMU: main vibration at 6 Hz, camera vibration at 28 Hz, noise at 42 Hz
    static func oakD() -> [SpectrumPoint] {
        spectrum { frequency in
            exp(-frequency / 25) * Double.random(in: 0.04..<0.06)
                + peak(at: 6, height: 0.5, width: 2.5, frequency: frequency)
                + peak(at: 12, height: 0.25, width: 3, frequency: frequency)
                + peak(at: 28, height: 0.18, width: 2, frequency: frequency)
                + peak(at: 42, height: 0.12, width: 3, frequency: frequency)
        }
    }

    private static func spectrum(_ magnitude: (Double) -> Double) -> [SpectrumPoint] {
        (0...pointCount).map { index in
            let frequency = Double(index) * frequencyStep
            return SpectrumPoint(frequency: frequency, magnitude: magnitude(frequency))
        }
    }

    /// Gaussian bump centered on `center` Hz
    private static func peak(at center: Double, height: Double, width: Double, frequency: Double) -> Double {
        height * exp(-pow(frequency - center, 2) / width)
    }
}
