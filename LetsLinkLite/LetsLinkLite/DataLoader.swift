import Foundation
import MapKit

/// Intermediate model matching scraper JSON schema
private struct ScrapedItem: Decodable {
    let source: String
    let name: String
    let lat: String
    let lon: String
}

/// Loads sample scraped data and converts to Event instances for mapping
struct DataLoader {
    static func loadScrapedEvents() -> [Event] {
        // Sample fallback events around San Francisco
        return [
            Event(title: "Sample SF Park Tour", date: "2025-05-01", coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)),
            Event(title: "SF Food Festival",   date: "2025-05-03", coordinate: CLLocationCoordinate2D(latitude: 37.7894, longitude: -122.4104)),
            Event(title: "Golden Gate Meetup",date: "2025-05-05", coordinate: CLLocationCoordinate2D(latitude: 37.8078, longitude: -122.4750)),
        ]
    }
}