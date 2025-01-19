import SwiftUI
import AVFoundation
import PhotosUI

class CameraViewModel: ObservableObject {
    @Published var frontImage: UIImage?
    @Published var backImage: UIImage?
    @Published var showingImagePicker = false
    @Published var isCapturingFront = true
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var showError = false
    @Published var showingNameInput = false
    @Published var preworkoutName = ""
    @Published var navigateToScan: PreworkoutScan?
    @Published var cameraPermissionDenied = false
    private var response: AnalysisResponse?
    
    func showCamera() {
        showingImagePicker = true
    }
    
    func resetCameraState() {
        if isCapturingFront && frontImage != nil {
            isCapturingFront = false
        }
    }
    
    func convertToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        return imageData.base64EncodedString()
    }
    
    @MainActor
    func analyzePreworkout() {
        guard let backImage = backImage,
              let base64String = convertToBase64(backImage) else {
            self.error = "Failed to process image"
            self.showError = true
            return
        }
        
        isAnalyzing = true
        
        Task {
            do {
                let response = try await NetworkManager.shared.analyzePreworkout(imageBase64: base64String)
                self.response = response
                showingNameInput = true
                isAnalyzing = false
            } catch {
                isAnalyzing = false
                self.error = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    @MainActor
    func saveScanWithName(_ name: String, response: AnalysisResponse) {
        let scan = PreworkoutScan(
            id: UUID(),
            name: name,
            frontImage: frontImage ?? UIImage(),
            ingredients: response.ingredients.map { $0.name },
            effects: response.ingredients.flatMap { $0.effects },
            qualities: [
                "pump": response.qualities.pump,
                "energy": response.qualities.energy,
                "focus": response.qualities.focus,
                "recovery": response.qualities.recovery,
                "endurance": response.qualities.endurance
            ],
            rating: 0.0,
            reviews: []
        )
        
        DataManager.shared.saveScan(scan)
        navigateToScan = scan
        
        // Reset camera state
        frontImage = nil
        backImage = nil
        isCapturingFront = true
        preworkoutName = ""
    }
    
    func handleSave() {
        guard !preworkoutName.isEmpty, let response = response else { return }
        
        Task { @MainActor in
            saveScanWithName(preworkoutName, response: response)
            showingNameInput = false
        }
    }
    
    func handleCancel() {
        preworkoutName = ""
        showingNameInput = false
    }
}

struct NameInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    let onSave: () -> Void
    
    var body: some View {
        Form {
            TextField("Preworkout Name", text: $name)
        }
        .navigationTitle("Name Your Preworkout")
        .navigationBarItems(
            leading: Button("Cancel") {
                name = ""
                dismiss()
            },
            trailing: Button("Save") {
                onSave()
                dismiss()
            }
            .disabled(name.isEmpty)
        )
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.frontImage == nil || viewModel.backImage == nil {
                    Text(viewModel.isCapturingFront ? "Take a picture of the front" : "Take a picture of the ingredients")
                        .font(.headline)
                    
                    Button(action: {
                        viewModel.showCamera()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                
                HStack(spacing: 20) {
                    if let frontImage = viewModel.frontImage {
                        VStack {
                            Image(uiImage: frontImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                            Text("Front")
                                .font(.caption)
                        }
                    }
                    
                    if let backImage = viewModel.backImage {
                        VStack {
                            Image(uiImage: backImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                            Text("Back")
                                .font(.caption)
                        }
                    }
                }
                
                if viewModel.frontImage != nil && viewModel.backImage != nil {
                    Button(action: {
                        viewModel.analyzePreworkout()
                    }) {
                        Text("Analyze Preworkout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scan")
            .sheet(isPresented: $viewModel.showingImagePicker, onDismiss: {
                viewModel.resetCameraState()
            }) {
                ImagePicker(
                    image: viewModel.isCapturingFront ? $viewModel.frontImage : $viewModel.backImage
                )
            }
            .sheet(isPresented: $viewModel.showingNameInput) {
                NavigationStack {
                    NameInputView(name: $viewModel.preworkoutName) {
                        viewModel.handleSave()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error ?? "An unknown error occurred")
            }
            .navigationDestination(item: $viewModel.navigateToScan) { scan in
                PreworkoutDetailView(scan: scan, viewModel: HomeViewModel())
            }
            .overlay {
                if viewModel.isAnalyzing {
                    ProgressView("Analyzing...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
    }
} 