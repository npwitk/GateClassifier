//
//  Prediction.swift
//  GateClassifier
//
//  Created by Nonprawich I. on 2/2/25.
//

import Foundation

class Prediction: Identifiable {
    var gateName: String = ""
    var confidencePercentage: String = ""
    
    init(gateName: String, confidencePercentage: String) {
        self.gateName = gateName
        self.confidencePercentage = confidencePercentage
    }
}
