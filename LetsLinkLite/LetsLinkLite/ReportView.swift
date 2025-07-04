import SwiftUI

/// View to report a user
struct ReportView: View {
    @Environment(\.presentationMode) private var presentationMode
    let reportedUserName: String
    @State private var selectedReason: String? = nil
    private let reasons = [
        "Inappropriate content",
        "Spam",
        "Harassment",
        "Other"
    ]
    @State private var otherText: String = ""

    var body: some View {
        Form {
            Section(header: Text("Why are you reporting \(reportedUserName)?")) {
                ForEach(reasons, id: \.self) { reason in
                    HStack {
                        Text(reason)
                        Spacer()
                        if selectedReason == reason {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedReason = reason }
                }
                if selectedReason == "Other" {
                    TextField("Enter reason", text: $otherText)
                }
            }
            Section {
                Button("Submit Report") {
                    // TODO: send report payload
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedReason == nil)
            }
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportView(reportedUserName: "Laura West")
        }
    }
}
#endif