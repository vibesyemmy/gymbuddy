import CoreLocation
import Observation

/// Tracks distance and route for a workout. Keeps running in the background
/// (requires the `location` background mode set in project.yml).
@Observable
final class LocationTracker: NSObject, CLLocationManagerDelegate {
    private(set) var distanceMeters: Double = 0
    private(set) var route: [CLLocationCoordinate2D] = []
    private(set) var authorization: CLAuthorizationStatus = .notDetermined

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var lastLocation: CLLocation?
    @ObservationIgnored private var isRecording = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        authorization = manager.authorizationStatus
    }

    var isDenied: Bool { authorization == .denied || authorization == .restricted }

    func requestPermissionIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func start() {
        isRecording = true
        lastLocation = nil
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func pause() {
        isRecording = false
        lastLocation = nil
    }

    func resume() {
        isRecording = true
        lastLocation = nil
    }

    func stop() {
        isRecording = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording else { return }
        for location in locations {
            // Drop poor or stale fixes.
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 25 else { continue }
            guard abs(location.timestamp.timeIntervalSinceNow) < 10 else { continue }
            if let last = lastLocation {
                let meters = location.distance(from: last)
                let seconds = location.timestamp.timeIntervalSince(last.timestamp)
                // Ignore GPS jumps (> 12 m/s is faster than any human runs) and jitter.
                if seconds > 0, meters / seconds > 12 { continue }
                if meters < 2 { continue }
                distanceMeters += meters
            }
            lastLocation = location
            route.append(location.coordinate)
        }
    }
}
