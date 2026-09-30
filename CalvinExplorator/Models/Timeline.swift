import Foundation

/// Rolling history, oldest sample first, that keeps at most `capacity` samples
struct Timeline<Sample> {
    /// Samples kept per sensor timeline unless a sensor needs more
    static var defaultCapacity: Int { 60 }

    let capacity: Int
    private(set) var samples: [Sample] = []

    init(capacity: Int = Self.defaultCapacity) {
        self.capacity = capacity
    }

    var latest: Sample? { samples.last }

    mutating func append(_ sample: Sample) {
        samples.append(sample)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }
}
