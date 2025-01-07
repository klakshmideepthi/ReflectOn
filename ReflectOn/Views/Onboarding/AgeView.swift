//
//  AgeView.swift
//  ReflectOn
//
//  Created by Lakshmi Deepthi Kurugundla on 1/3/25.
//

import SwiftUI

struct AgeView: View {
    @Binding var currentStep: Int
    @Binding var age: String

    var body: some View {
        VStack {
            Text("Please enter your age.")
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onReceive(age.publisher.collect()) { input in
                    self.age = String(input.prefix(3).filter { "0123456789".contains($0) })
                }
        }
        .padding()
    }
}
