import SwiftUI
import SwiftAI

struct ComputerVisionExample: View {
    @State private var selectedImage: UIImage?
    @State private var analysisResults: [String: String] = [:]
    @State private var isAnalyzing = false
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Computer Vision Analysis")
                .font(.title)
                .fontWeight(.bold)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Tap to select image")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
            
            Button(action: analyzeImage) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "eye")
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Analyze Image")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedImage != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(selectedImage == nil || isAnalyzing)
            
            if !analysisResults.isEmpty {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(Array(analysisResults.keys.sorted()), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(key)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(analysisResults[key] ?? "")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func analyzeImage() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        analysisResults.removeAll()
        
        // Simulate computer vision analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let imageSize = image.size
            let aspectRatio = imageSize.width / imageSize.height
            
            // Image Classification
            let objects = classifyObjects(image)
            analysisResults["Object Detection"] = objects
            
            // Face Recognition
            let faces = detectFaces(image)
            analysisResults["Face Detection"] = faces
            
            // Image Properties
            let properties = """
            • Resolution: \(Int(imageSize.width)) × \(Int(imageSize.height))
            • Aspect Ratio: \(String(format: "%.2f", aspectRatio))
            • File Size: \(estimateFileSize(image))
            • Color Space: RGB
            """
            analysisResults["Image Properties"] = properties
            
            // Text Recognition (OCR)
            let text = extractText(image)
            analysisResults["Text Recognition"] = text
            
            // Scene Classification
            let scene = classifyScene(image)
            analysisResults["Scene Classification"] = scene
            
            // Image Quality
            let quality = assessImageQuality(image)
            analysisResults["Image Quality"] = quality
            
            isAnalyzing = false
        }
    }
    
    private func classifyObjects(_ image: UIImage) -> String {
        let objects = [
            "Person": 0.95,
            "Car": 0.87,
            "Building": 0.82,
            "Tree": 0.78,
            "Phone": 0.91
        ]
        
        let detectedObjects = objects.filter { $0.value > 0.8 }
        return detectedObjects.isEmpty ? "No objects detected" : 
            detectedObjects.map { "\($0.key) (\(String(format: "%.0f", $0.value * 100))%)" }.joined(separator: "\n")
    }
    
    private func detectFaces(_ image: UIImage) -> String {
        let faceCount = Int.random(in: 0...3)
        if faceCount == 0 {
            return "No faces detected"
        } else if faceCount == 1 {
            return "1 face detected (Confidence: 92%)"
        } else {
            return "\(faceCount) faces detected (Average confidence: 89%)"
        }
    }
    
    private func estimateFileSize(_ image: UIImage) -> String {
        let size = Int.random(in: 500...5000)
        return "\(size) KB"
    }
    
    private func extractText(_ image: UIImage) -> String {
        let texts = ["Hello World", "Sample Text", "OCR Test", "Swift AI"]
        let randomText = texts.randomElement() ?? "No text detected"
        return randomText
    }
    
    private func classifyScene(_ image: UIImage) -> String {
        let scenes = [
            "Indoor": 0.85,
            "Outdoor": 0.92,
            "Urban": 0.78,
            "Nature": 0.88,
            "Portrait": 0.91
        ]
        
        let bestScene = scenes.max { $0.value < $1.value }
        return "\(bestScene?.key ?? "Unknown") (Confidence: \(String(format: "%.0f", (bestScene?.value ?? 0) * 100))%)"
    }
    
    private func assessImageQuality(_ image: UIImage) -> String {
        let quality = Int.random(in: 70...95)
        let qualityLevel = quality > 90 ? "Excellent" : quality > 80 ? "Good" : quality > 70 ? "Fair" : "Poor"
        return "\(qualityLevel) (\(quality)%)"
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
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
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ComputerVisionExample()
} 