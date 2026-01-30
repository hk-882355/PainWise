import Foundation
import CoreLocation

@MainActor
final class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var currentWeather: WeatherSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // OpenWeatherMap API (後で設定)
    private var apiKey: String {
        // TODO: Replace with actual API key from environment or config
        ProcessInfo.processInfo.environment["OPENWEATHERMAP_API_KEY"] ?? ""
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Location Authorization

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    // MARK: - Fetch Weather

    func fetchCurrentWeather() async {
        isLoading = true
        errorMessage = nil

        // Get current location
        locationManager.requestLocation()

        // Wait for location update (with timeout)
        let startTime = Date()
        while currentLocation == nil && Date().timeIntervalSince(startTime) < 10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        guard let location = currentLocation else {
            errorMessage = "位置情報を取得できませんでした"
            isLoading = false
            return
        }

        do {
            let weather = try await fetchWeather(for: location)
            currentWeather = weather
        } catch {
            errorMessage = "天気情報を取得できませんでした: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func fetchWeather(for location: CLLocation) async throws -> WeatherSnapshot {
        // If no API key, return mock data
        if apiKey.isEmpty {
            return createMockWeather()
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

        return WeatherSnapshot(
            pressure: weatherResponse.main.pressure,
            temperature: weatherResponse.main.temp,
            humidity: weatherResponse.main.humidity,
            weatherCondition: weatherResponse.weather.first?.main ?? "Unknown",
            timestamp: Date()
        )
    }

    // MARK: - Mock Data

    private func createMockWeather() -> WeatherSnapshot {
        WeatherSnapshot(
            pressure: 1008 + Double.random(in: -10...10),
            temperature: 15 + Double.random(in: -5...5),
            humidity: 60 + Double.random(in: -20...20),
            weatherCondition: ["Clear", "Clouds", "Rain", "Snow"].randomElement() ?? "Clear",
            timestamp: Date()
        )
    }

    // MARK: - Forecast

    func fetchForecast() async throws -> [WeatherForecast] {
        // Mock forecast data for now
        let today = Date()
        var forecasts: [WeatherForecast] = []

        for dayOffset in 0..<3 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let basePressure = 1013.0
            let pressureChange = Double.random(in: -15...5)
            let pressure = basePressure + pressureChange

            let forecast = WeatherForecast(
                date: date,
                pressure: pressure,
                pressureChange: pressureChange,
                temperature: 15 + Double.random(in: -5...10),
                humidity: 60 + Double.random(in: -20...20),
                condition: randomWeatherCondition(),
                precipitationProbability: Int.random(in: 0...100)
            )

            forecasts.append(forecast)
        }

        return forecasts
    }

    private func randomWeatherCondition() -> WeatherCondition {
        [.sunny, .cloudy, .rainy, .partlyCloudy].randomElement() ?? .sunny
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.last
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - OpenWeatherMap Response

struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
}

struct MainWeather: Codable {
    let temp: Double
    let pressure: Double
    let humidity: Double
}

struct WeatherDescription: Codable {
    let main: String
    let description: String
}

// MARK: - Errors

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .noData:
            return "データが取得できませんでした"
        }
    }
}
