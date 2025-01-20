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
    
    private func checkCameraConfiguration() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            self.error = "Camera device not available"
            self.showError = true
            return
        }
        
        do {
            let session = AVCaptureSession()
            try session.addInput(AVCaptureDeviceInput(device: device))
            session.sessionPreset = .photo
        } catch {
            self.error = "Failed to configure camera: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    func showCamera() {
        checkCameraConfiguration()
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
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    if viewModel.frontImage == nil || viewModel.backImage == nil {
                        // Instructions and status
                        Text(viewModel.isCapturingFront ? "Take a picture of the front" : "Take a picture of the ingredients")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.bottom, 30)
                    }
                    
                    // Photos display
                    if viewModel.frontImage != nil || viewModel.backImage != nil {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            HStack(spacing: 20) {
                                if let frontImage = viewModel.frontImage {
                                    PhotoView(image: frontImage, title: "Front")
                                }
                                
                                if let backImage = viewModel.backImage {
                                    PhotoView(image: backImage, title: "Back")
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            if viewModel.frontImage != nil && viewModel.backImage != nil {
                                Button(action: {
                                    viewModel.analyzePreworkout()
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles.magnifyingglass")
                                        Text("Analyze Preworkout")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                    .shadow(radius: 4)
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Camera button
                    if viewModel.frontImage == nil || viewModel.backImage == nil {
                        Button(action: {
                            viewModel.showCamera()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 80, height: 80)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 48)
                    }
                }
            }
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
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Analyzing...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 8)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PhotoView: View {
    let image: UIImage
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 280)
                .cornerRadius(16)
                .shadow(radius: 4)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
} 