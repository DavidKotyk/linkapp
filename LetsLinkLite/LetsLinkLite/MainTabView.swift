import SwiftUI
import MapKit
import Foundation
import CoreLocation
import UIKit

/// Shared event model used throughout the app
struct Event: Identifiable {
    let id = UUID()
    let source: String            // e.g. "Eventbrite", "OSM"
    let title: String
    /// Single date/time string; placeholder 'NA' if unavailable
    let date: String
    let coordinate: CLLocationCoordinate2D
    /// Full description of the event; default 'NA' when not provided
    let description: String
    /// Event URL for details
    let url: String
    
    /// Designated initializer with defaults for description & url
    init(
        source: String = "Unknown",
        title: String,
        date: String,
        coordinate: CLLocationCoordinate2D,
        description: String = "NA",
        url: String = "NA"
    ) {
        self.source = source
        self.title = title
        self.date = date
        self.coordinate = coordinate
        self.description = description
        self.url = url
    }

}




struct MainTabView: View {
    // Event service fetching live data
    @StateObject private var service = EventService()
    private var sampleEvents: [Event] { service.events }
    // Selected tab: 0=Events, 1=New Event, 2=Profile
    @State private var selectedTab: Int = 0
    // Camera position for map views (default: San Francisco)
    // Map region for clustering
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    // Selected event for detail sheet
    @State private var sheetEvent: Event? = nil
    // Events in a tapped cluster to show selection list
    @State private var clusterEvents: [Event]? = nil
    // Location manager from app environment
    @EnvironmentObject private var locationManager: LocationManager
    // Show alert if location permission denied
    @State private var showLocationDeniedAlert: Bool = false
    // Prevent recentering after the user has interacted with the map
    @State private var hasCenteredOnUserLocation: Bool = false
    // Current user ID saved after login
    @AppStorage("userId") private var userId: Int = 0

    /// Events tab view encapsulating map and related modifiers
    private var eventsTab: some View {
        NavigationView {
            ClusteredMapView(
                events: $service.events,
                region: $region,
                selectedEvent: $sheetEvent,
                clusterEvents: $clusterEvents
            )
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                Text("Events loaded: \(service.events.count)")
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .font(.caption)
                    .cornerRadius(6)
                    .padding([.top, .leading], 16)
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ChatView()) {
                        Image(systemName: "message")
                    }
                }
            }
            .sheet(item: $sheetEvent) { event in
                NavigationView {
                    EventDetailView(event: event)
                }
            }
        }
    }


    var body: some View {
        TabView(selection: $selectedTab) {
            eventsTab
                .tabItem { Label("Events", systemImage: "map") }
                .tag(0)

            // Create Event tab (center)
            NavigationView {
                NewEventFormView()
            }
            .tabItem { Label("", systemImage: "plus.circle.fill") }
            .tag(1)

            // Profile tab (right)
            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { selectedTab = 0 }) {
                                Image(systemName: "chevron.left")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: ReportView(reportedUserName: "Laura West")) {
                                Text("Report").foregroundColor(.red)
                            }
                        }
                    }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(2)
        }
        // For simplicity during testing, fetch events for a static list of major cities
        .task {
            // During testing, only fetch events for a single city to speed up cycles
            let testCities = ["San Francisco, CA"]
            await service.loadEvents(cities: testCities)
        }
        // Show list when a cluster is tapped
        .sheet(isPresented: Binding(
            get: { clusterEvents != nil },
            set: { newVal in if !newVal { clusterEvents = nil } }
        )) {
            if let events = clusterEvents {
                ClusterListView(
                    events: events,
                    selectedEvent: $sheetEvent,
                    clusterEvents: $clusterEvents
                )
            }
        }
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif