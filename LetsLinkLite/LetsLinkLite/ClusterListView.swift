import SwiftUI
import MapKit

/// List view for events in a tapped cluster
struct ClusterListView: View {
    let events: [Event]
    @Binding var selectedEvent: Event?
    @Binding var clusterEvents: [Event]?

    var body: some View {
        NavigationView {
            List(events, id: \.id) { event in
                Button(action: {
                    // Select the tapped event and dismiss cluster list
                    selectedEvent = event
                    clusterEvents = nil
                }) {
                    Text(event.title)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        clusterEvents = nil
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ClusterListView_Previews: PreviewProvider {
    @State static var sampleEvent: Event? = nil
    @State static var clusterEvents: [Event]? = [
        Event(title: "Event A", date: "2025-07-04", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
        Event(title: "Event B", date: "2025-07-05", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    ]
    static var previews: some View {
        ClusterListView(
            events: clusterEvents!,
            selectedEvent: $sampleEvent,
            clusterEvents: $clusterEvents
        )
    }
}
#endif