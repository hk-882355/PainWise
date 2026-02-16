import Foundation
import CoreLocation
import FirebaseCrashlytics

@MainActor
final class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var currentWeather: WeatherSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let locationTimeout: TimeInterval = 10
    private let forecastDays = 5
    private var lastWeatherFetchTime: Date?
    private var lastForecastFetchTime: Date?
    private var cachedForecasts: [WeatherForecast]?
    private let minimumFetchInterval: TimeInterval = 600 // 10 minutes

    // OpenWeatherMap API
    private var apiKey: String {
        (Bundle.main.infoDictionary?["OpenWeatherMapAPIKey"] as? String) ?? ""
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
        // Rate limiting: skip if fetched recently
        if let lastFetch = lastWeatherFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval,
           currentWeather != nil {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let location = try await fetchLocation()
            let weather = try await fetchWeather(for: location)
            currentWeather = weather
            lastWeatherFetchTime = Date()
        } catch {
            errorMessage = "天気情報を取得できませんでした。しばらくしてからお試しください。"
            #if DEBUG
            print("Weather fetch error: \(error)")
            #endif
            let sanitizedError = NSError(domain: "WeatherService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Weather fetch failed"])
            Crashlytics.crashlytics().record(error: sanitizedError)
        }

        isLoading = false
    }

    private func fetchWeather(for location: CLLocation) async throws -> WeatherSnapshot {
        // If no API key, return mock data in Debug only
        if apiKey.isEmpty {
            #if DEBUG
            return createMockWeather()
            #else
            throw WeatherError.missingAPIKey
            #endif
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
        // Rate limiting: return cached forecasts if fetched recently
        if let lastFetch = lastForecastFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval,
           let cached = cachedForecasts {
            return cached
        }

        if apiKey.isEmpty {
            #if DEBUG
            let forecasts = createMockForecast(days: forecastDays)
            cachedForecasts = forecasts
            lastForecastFetchTime = Date()
            return forecasts
            #else
            throw WeatherError.missingAPIKey
            #endif
        }

        let location = try await fetchLocation()
        let forecasts = try await fetchFiveDayForecast(for: location, days: forecastDays)
        cachedForecasts = forecasts
        lastForecastFetchTime = Date()
        return forecasts
    }

    private func randomWeatherCondition() -> WeatherCondition {
        [.sunny, .cloudy, .rainy, .partlyCloudy].randomElement() ?? .sunny
    }

    // MARK: - Location Helpers

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var locationTimeoutTask: Task<Void, Never>?

    private func fetchLocation() async throws -> CLLocation {
        if let location = currentLocation {
            return location
        }

        // Guard against re-entrant calls that would overwrite the continuation
        if locationContinuation != nil {
            throw WeatherError.locationUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()

            locationTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(self?.locationTimeout ?? 10))
                guard !Task.isCancelled else { return }
                guard let self, let pending = self.locationContinuation else { return }
                self.locationContinuation = nil
                pending.resume(throwing: WeatherError.locationUnavailable)
            }
        }
    }

    // MARK: - Forecast Fetch

    private func fetchFiveDayForecast(for location: CLLocation, days: Int) async throws -> [WeatherForecast] {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let forecastResponse = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)

        let calendar = Calendar.weatherCalendar(timeZoneOffset: forecastResponse.city.timezone)
        let grouped = Dictionary(grouping: forecastResponse.list) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }

        let sortedDates = grouped.keys.sorted()
        let dailyBuckets = sortedDates.prefix(days)

        var forecasts: [WeatherForecast] = []
        var previousPressure: Double?

        for date in dailyBuckets {
            guard let items = grouped[date], !items.isEmpty else { continue }

            let pressures = items.map { $0.main.pressure }
            let temperatures = items.map { $0.main.temp }
            let humidities = items.map { $0.main.humidity }
            let precipitation = items.map { $0.pop ?? 0 }
            let conditionMain = mostCommonWeatherMain(in: items)

            let averagePressure = pressures.average
            let pressureChange = previousPressure == nil ? 0 : averagePressure - (previousPressure ?? averagePressure)

            let forecast = WeatherForecast(
                date: date,
                pressure: averagePressure,
                pressureChange: pressureChange,
                temperature: temperatures.average,
                humidity: humidities.average,
                condition: mapWeatherCondition(conditionMain),
                precipitationProbability: Int((precipitation.max() ?? 0) * 100)
            )

            forecasts.append(forecast)
            previousPressure = averagePressure
        }

        return forecasts
    }

    private func mapWeatherCondition(_ main: String) -> WeatherCondition {
        switch main.lowercased() {
        case "clear":
            return .sunny
        case "clouds":
            return .cloudy
        case "rain", "drizzle":
            return .rainy
        case "snow":
            return .snowy
        case "thunderstorm":
            return .stormy
        default:
            return .partlyCloudy
        }
    }

    // MARK: - Mock Data

    private func createMockForecast(days: Int) -> [WeatherForecast] {
        let today = Date()
        var forecasts: [WeatherForecast] = []
        var previousPressure: Double?

        for dayOffset in 0..<days {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let basePressure = 1013.0
            let pressure = basePressure + Double.random(in: -15...10)
            let pressureChange = previousPressure == nil ? 0 : pressure - (previousPressure ?? pressure)

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
            previousPressure = pressure
        }

        return forecasts
    }

    private func mostCommonWeatherMain(in items: [OpenWeatherForecastItem]) -> String {
        let counts = Dictionary(grouping: items) { $0.weather.first?.main ?? "Clouds" }
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Clouds"
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationTimeoutTask?.cancel()
            locationTimeoutTask = nil
            currentLocation = locations.last
            if let location = locations.last, let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationTimeoutTask?.cancel()
            locationTimeoutTask = nil
            errorMessage = "位置情報の取得に失敗しました"
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: WeatherError.locationUnavailable)
            }
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

struct OpenWeatherResponse: Codable, Sendable {
    let main: MainWeather
    let weather: [WeatherDescription]
}

struct MainWeather: Codable, Sendable {
    let temp: Double
    let pressure: Double
    let humidity: Double
}

struct WeatherDescription: Codable, Sendable {
    let main: String
    let description: String
}

struct OpenWeatherForecastResponse: Codable, Sendable {
    let list: [OpenWeatherForecastItem]
    let city: OpenWeatherCity
}

struct OpenWeatherForecastItem: Codable, Sendable {
    let dt: TimeInterval
    let main: OpenWeatherForecastMain
    let weather: [WeatherDescription]
    let pop: Double?
}

struct OpenWeatherForecastMain: Codable, Sendable {
    let temp: Double
    let pressure: Double
    let humidity: Double
}

struct OpenWeatherCity: Codable, Sendable {
    let timezone: Int
}

// MARK: - Errors

enum WeatherError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case noData
    case missingAPIKey
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .noData:
            return "データが取得できませんでした"
        case .missingAPIKey:
            return "APIキーが設定されていません"
        case .locationUnavailable:
            return "位置情報を取得できませんでした"
        }
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Calendar {
    static func weatherCalendar(timeZoneOffset: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(secondsFromGMT: timeZoneOffset) {
            calendar.timeZone = timeZone
        }
        return calendar
    }
}
