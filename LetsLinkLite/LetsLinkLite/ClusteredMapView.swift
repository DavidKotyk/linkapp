import SwiftUI
import MapKit

/// A UIViewRepresentable wrapper around MKMapView supporting clustering of Event annotations.
struct ClusteredMapView: UIViewRepresentable {
    @Binding var events: [Event]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedEvent: Event?
    // Events in the currently selected cluster (nil when no cluster selected)
    @Binding var clusterEvents: [Event]?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
        )
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update region
        uiView.setRegion(region, animated: true)
        // Remove old annotations
        let existing = uiView.annotations.filter { $0 is EventAnnotation }
        uiView.removeAnnotations(existing)
        // Add new annotations
        let annotations = events.map { EventAnnotation(event: $0) }
        uiView.addAnnotations(annotations)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredMapView
        init(_ parent: ClusteredMapView) {
            self.parent = parent
            super.init()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                    for: cluster
                ) as! MKMarkerAnnotationView
                view.clusteringIdentifier = "event"
                view.markerTintColor = .systemBlue
                view.glyphText = "\(cluster.memberAnnotations.count)"
                return view
            }
            guard let eventAnno = annotation as? EventAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
                for: eventAnno
            ) as! MKMarkerAnnotationView
            view.clusteringIdentifier = "event"
            view.canShowCallout = true
            view.glyphImage = UIImage(systemName: "mappin.circle.fill")
            view.markerTintColor = .red
            view.canShowCallout = true
            // Add detail button for selection
            let button = UIButton(type: .detailDisclosure)
            view.rightCalloutAccessoryView = button
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            if let eventAnno = view.annotation as? EventAnnotation {
                parent.selectedEvent = eventAnno.event
            }
        }

        // Handle cluster tap: capture cluster events
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                let events = cluster.memberAnnotations.compactMap { ($0 as? EventAnnotation)?.event }
                parent.clusterEvents = events
            }
        }
        
        // Keep SwiftUI region in sync
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

/// MKAnnotation subclass for Event
class EventAnnotation: NSObject, MKAnnotation {
    let event: Event
    var coordinate: CLLocationCoordinate2D { event.coordinate }
    var title: String? { event.title }
    var subtitle: String? { event.source }

    init(event: Event) {
        self.event = event
    }
}