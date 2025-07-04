import SwiftUI

/// Form for creating a new event
struct NewEventFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var title: String = ""
    @State private var date: String = ""
    @State private var location: String = ""
    @State private var description: String = ""

    var body: some View {
        Form {
            Section(header: Text("Event Details")) {
                TextField("Title", text: $title)
                TextField("Date and Time", text: $date)
                TextField("Location", text: $location)
                TextEditor(text: $description)
                    .frame(height: 100)
            }
            Section {
                Button("Create Event") {
                    // TODO: Implement event creation logic
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("New Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct NewEventFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewEventFormView()
        }
    }
}
#endif