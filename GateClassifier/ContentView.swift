//
//  ContentView.swift
//  GateClassifier
//
//  Created by Nonprawich I. on 1/2/25.
//

import SwiftUI
import PhotosUI
import CoreML
import Vision

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isAlertPresent: Bool = false
    @State private var predictions: [Prediction] = []
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                // Image Section
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300)
                    .padding(.horizontal)
                
                Text("I think it's \(predictions[0].gateName) gate")
                    .bold()
                
                // Predictions List
                List(predictions) { prediction in
                    HStack {
                        Text(prediction.gateName)
                            .font(.system(.body, design: .rounded))
                        Spacer()
                        Text(prediction.confidencePercentage)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .padding()
                
                // Reset Button
                Button("Reset Picture") {
                    isAlertPresent = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.bottom)
                .alert("Reset Action", isPresented: $isAlertPresent) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        predictions = []
                        selectedItem = nil
                        selectedImage = nil
                    }
                } message: {
                    Text("This action will clear the picture and its prediction")
                }
            } else {
                // PhotosPicker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ContentUnavailableView("No Picture",
                                           systemImage: "photo.badge.plus",
                                           description: Text("Tap to select a picture from your Photo Library")
                    )
                    .frame(height: 300)
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    predictions = [] // Clear previous predictions
                    processImageClassification(uiImage)
                }
            }
        }
        .onAppear(perform: {
            requestPhotoLibraryAccess()
        })
    }
    
    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    print("Access granted.")
                } else {
                    print("Access denied.")
                }
            }
        case .restricted, .denied:
            print("Access denied or restricted.")
        case .authorized:
            print("Access already granted.")
        case .limited:
            print("Access limited.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }
    
    private func processImageClassification(_ image: UIImage) {
        
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? GateClassifier(configuration: defaultConfig)
        
        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }
        
        let imageClassifierModel = imageClassifier.model
        
        guard let model = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        let imageClassificationRequest = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                print("Failed to classify image")
                return
            }
            
            results.forEach { result in
                let condidence = String(format: "%.2f", result.confidence * 100)
                let prediction = Prediction(gateName: result.identifier,
                                            confidencePercentage: "\(condidence)%")
                predictions.append(prediction)
            }
        }
        
        guard let cgImage = image.cgImage else {
            print("Failed to get cgImage data")
            return
        }
        
        let requests: [VNRequest] = [imageClassificationRequest]
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        try? handler.perform(requests)
    }
}


#Preview {
    ContentView()
}
