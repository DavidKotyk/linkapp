import Foundation
import MapKit

/// Response model returned by scraper API (encodable/decodable for caching)
struct ScrapedResponse: Codable {
    let source: String?
    let name: String?
    let url: String?
    let date: String?
    let venue: String?
    let lat: String?
    let lon: String?
    // Optional description field, may be 'NA' or real text
    let description: String?
}

/// Service to fetch events from remote scraper API
@MainActor
class EventService: ObservableObject {
    @Published var events: [Event] = []
    // Local cache file for offline events
    private let eventsCacheURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("events_cache.json")
    }()
    /// API base URL configured in Info.plist or fallback to localhost for simulator
    // API base URL: localhost for simulator; Info.plist for device
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"
        #else
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        assertionFailure("API_BASE_URL must be set in Info.plist for device builds")
        return ""
        #endif
    }
    
    /// Load events for the given city asynchronously (replaces current events)
    func loadEvents(city: String) async {
        // Attempt to show cached events first (offline support)
        if let cachedData = try? Data(contentsOf: eventsCacheURL),
           let decoded = try? JSONDecoder().decode([ScrapedResponse].self, from: cachedData) {
            // Map cached items to Event models
            self.events = decoded.compactMap { item in
                guard let name = item.name,
                      let latStr = item.lat, let lonStr = item.lon,
                      let lat = Double(latStr), let lon = Double(lonStr) else { return nil }
                return Event(
                    source: item.source ?? "Unknown",
                    title: name,
                    date: item.date ?? "NA",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    description: item.description ?? "NA",
                    url: item.url ?? ""
                )
            }
        }
        // Debug: beginning loadEvents for single city
        print("🐛 EventService: loadEvents(city: '", city, "') starting")
        let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        // Build URL without trailing slash to match backend endpoint
        guard let url = URL(string: "\(baseURL)/events?city=\(encoded)") else {
            print("🐛 EventService: invalid URL for city: '", city, "'")
            return
        }
        print("🐛 EventService: request URL = \(url)")
        var request = URLRequest(url: url)
        // Attach auth token
        if let token = UserDefaults.standard.string(forKey: "accessToken"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            // Execute HTTP request
            let (data, response) = try await URLSession.shared.data(for: request)
            // Validate HTTP response status
            guard let http = response as? HTTPURLResponse else { return }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("🐛 EventService: server error \(http.statusCode): \(body)")
                return
            }
            print("🐛 EventService: HTTP status code = \(http.statusCode)")
            print("🐛 EventService: raw response data (first 500 chars)=\n\(String(data: data.prefix(500), encoding: .utf8) ?? "<binary>")")
            let decoder = JSONDecoder()
                // Try bare-array decode first
                let decodedItems: [ScrapedResponse]
                do {
                    decodedItems = try decoder.decode([ScrapedResponse].self, from: data)
                } catch {
                    // Fallback to wrapper shape {"events":[...]}
                    struct Wrapper: Decodable { let events: [ScrapedResponse] }
                    let wrapper = try decoder.decode(Wrapper.self, from: data)
                    decodedItems = wrapper.events
                }
            // Save raw responses to cache for offline use
            if let raw = try? JSONEncoder().encode(decodedItems) {
                try? raw.write(to: eventsCacheURL)
            }
            // Transform decoded items into Event instances
            self.events = decodedItems.compactMap { item in
                    guard let name = item.name,
                          let latStr = item.lat, let lonStr = item.lon,
                          let lat = Double(latStr), let lon = Double(lonStr)
                    else { return nil }
                    // Extract source and event fields
                    let sourceStr = item.source ?? "Unknown"
                    let dateStr = item.date ?? "NA"
                    let desc = item.description ?? "NA"
                    let urlStr = item.url ?? "NA"
                    return Event(
                        source: sourceStr,
                        title: name,
                        date: dateStr,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        description: desc,
                        url: urlStr
                    )
                }
                // Debug: log number of loaded events
                print("EventService: loaded \(self.events.count) events for city: \(city)")
        } catch {
            // Log any failures
            print("🐛 EventService: failed to load events for city '\(city)': \(error)")
        }
        }
    
    /// Obtain top metro cities around a given city via GPT-4 (including the city itself).
    /// Caches results in UserDefaults to avoid repeated API calls.
    func getMetroCities(around city: String) async -> [String] {
        // In DEBUG, skip metro expansion to reduce scraping load (only one city per user)
        #if DEBUG
        print("🔍 getMetroCities: DEBUG mode, skipping metro lookup for city '\(city)'")
        return []
        #endif
        let cacheKey = "metro_\(city)"
        // Local fallback map for common states (if no network or to avoid API calls)
        let defaultMetroMap: [String:[String]] = [
            "OH": ["Cleveland, OH","Columbus, OH","Cincinnati, OH","Dayton, OH"],
            "CA": ["Los Angeles, CA","San Diego, CA","San Jose, CA","San Francisco, CA"],
            "TX": ["Houston, TX","San Antonio, TX","Dallas, TX","Austin, TX"],
            "FL": ["Miami, FL","Orlando, FL","Tampa, FL","Jacksonville, FL"],
            "NY": ["New York, NY","Buffalo, NY","Rochester, NY","Syracuse, NY"],
            // ...add more as needed
        ]
        // If city includes state code and we have a local list, use it
        let parts = city.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2, let hubs = defaultMetroMap[String(parts[1])] {
            print("🔍 getMetroCities fallback for \(city): \(hubs)")
            return hubs
        }
        if let cached = UserDefaults.standard.stringArray(forKey: cacheKey) {
            return cached
        }
        // Retrieve API key from Info.plist or environment
        var apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        if apiKey == nil || apiKey!.isEmpty {
            apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        }
        guard let key = apiKey, !key.isEmpty else {
            print("🔍 getMetroCities: OPENAI_API_KEY not configured")
            return []
        }
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Prompt GPT-4 for the top 4 populous cities in the metro area
        let systemMsg = [
            "role": "system",
            "content": "You are an assistant that returns exactly a JSON array of the top 4 most populous cities in the same metropolitan area as the provided city, including the city itself."
        ]
        let userMsg = [
            "role": "user",
            "content": "List the top 4 most populous cities in the metropolitan area of \(city), including the city itself, in JSON array format."
        ]
        let body: [String:Any] = [
            "model": "gpt-4",
            "messages": [systemMsg, userMsg],
            "max_tokens": 200
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let resp = try JSONSerialization.jsonObject(with: data) as? [String:Any],
               let choices = resp["choices"] as? [[String:Any]],
               let msg = (choices.first?["message"] as? [String:Any])?["content"] as? String,
               let arrData = msg.data(using: .utf8),
               let metros = try? JSONDecoder().decode([String].self, from: arrData) {
                UserDefaults.standard.set(metros, forKey: cacheKey)
                print("🔍 getMetroCities(around: \(city)) → \(metros)")
                return metros
            }
        } catch {
            print("🔍 getMetroCities error for \(city): \(error)")
        }
        return []
    }

    /// Load events for multiple cities asynchronously and combine them into a single list.
    /// - Parameter cities: Array of city names (e.g. ["Uniontown, OH", "Akron, OH", "Canton, OH"]).
    func loadEvents(cities: [String]) async {
        var combined: [Event] = []
        let decoder = JSONDecoder()
        // Debug: beginning loadEvents for multiple cities: \(cities)
        print("🐛 EventService: loadEvents(cities: \(cities)) starting")
        for city in cities {
            print("🐛 EventService: loading for city: \(city)")
            let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
            // Build URL without trailing slash to match backend endpoint
            guard let url = URL(string: "\(baseURL)/events?city=\(encoded)") else {
                print("🐛 EventService: invalid URL for city: \(city)")
                continue
            }
            print("🐛 EventService: request URL = \(url)")
            var request = URLRequest(url: url)
            if let token = UserDefaults.standard.string(forKey: "accessToken"), !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse {
                    print("🐛 EventService: HTTP status code for \(city) = \(http.statusCode)")
                }
                print("🐛 EventService: raw data for \(city) (first 500 chars)=\n\(String(data: data.prefix(500), encoding: .utf8) ?? "<binary>")")
                // Decode array of ScrapedResponse or wrapper
                let decodedItems: [ScrapedResponse]
                do {
                    decodedItems = try decoder.decode([ScrapedResponse].self, from: data)
                } catch {
                    struct Wrapper: Decodable { let events: [ScrapedResponse] }
                    let wrapper = try decoder.decode(Wrapper.self, from: data)
                    decodedItems = wrapper.events
                }
                // Map to Event and append
                let eventsForCity = decodedItems.compactMap { item -> Event? in
                    guard let name = item.name,
                          let latStr = item.lat, let lonStr = item.lon,
                          let lat = Double(latStr), let lon = Double(lonStr)
                    else { return nil }
                    // Extract source and fields
                    let sourceStr = item.source ?? "Unknown"
                    let dateStr = item.date ?? "NA"
                    let desc = item.description ?? "NA"
                    let urlStr = item.url ?? "NA"
                    return Event(
                        source: sourceStr,
                        title: name,
                        date: dateStr,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        description: desc,
                        url: urlStr
                    )
                }
                combined.append(contentsOf: eventsForCity)
                // Debug: log count per city
                print("EventService: loaded \(eventsForCity.count) events for city: \(city)")
            } catch {
                print("EventService: failed to load events for city \(city): \(error)")
            }
        }
        // Replace the published events array
        self.events = combined
    }
}
