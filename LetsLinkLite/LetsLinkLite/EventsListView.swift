import SwiftUI
import MapKit

struct EventsListView: View {
    // Sample events with coordinates (San Francisco, Los Angeles, New York)
    let events = [
        Event(title: "Event A", date: "2025-05-01", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
        Event(title: "Event B", date: "2025-06-15", coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)),
        Event(title: "Event C", date: "2025-07-20", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
    ]

    var body: some View {
        NavigationView {
            List(events) { event in
                NavigationLink(destination: EventChatView(event: event)) {
                    VStack(alignment: .leading) {
                        Text(event.title).font(.headline)
                        Text(event.date).font(.subheadline)
                    }
                }
            }
            .navigationTitle("Events")
        }
    }
}

#if DEBUG
struct EventsListView_Previews: PreviewProvider {
    static var previews: some View {
        EventsListView()
    }
}
#endif