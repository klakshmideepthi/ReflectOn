//
//  GenderView.swift
//  ReflectOn
//
//  Created by Lakshmi Deepthi Kurugundla on 1/3/25.
//

import SwiftUI

struct GenderView: View {
    @Binding var currentStep: Int
    @Binding var gender: String

    var body: some View {
        VStack {
            Text("Please enter your gender.")
            TextField("Gender", text: $gender)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
}
