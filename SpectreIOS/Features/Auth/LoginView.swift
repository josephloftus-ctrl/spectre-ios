import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var hostURL = ""
    @State private var apiKey = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Spectre")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading) {
                Text("Server Host")
                TextField("https://api.spectre.com", text: $hostURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                Text("API Key")
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            Button(action: {
                // TODO: Validate credentials
                isAuthenticated = true
            }) {
                Text("Connect")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}
