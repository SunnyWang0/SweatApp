//
//  ProductInfoView.swift
//  Sweat
//
//  Created by Nikash P on 1/18/25.
//


import SwiftUI

struct ProductInfoView: View {
    let productImage: Image // Image of the pre-workout/product
    let productName: String
    let productDetails: String // e.g., "Red Blend 2020"
    let rating: Double? // Optional rating (e.g., 3.8)
    let ratingCount: Int? // Optional number of ratings (e.g., 87)
    let price: Double? // Optional price (e.g., 10.07)
    let priceDisclaimer: String? //Optional text below price, for example "Based on prices from Vivino users"

    var body: some View {
        VStack(spacing: 0) {
            // Product Image (Top Part, potentially with background)
            ZStack(alignment: .top) {
                productImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 100) // Adjust height as needed
                    .offset(y: 150)
                
                
            }

            VStack(alignment: .leading, spacing: 8) {
                // Product Name and Details
                Text(productName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(productDetails)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Rating (Conditional Display)
                if let rating = rating, let ratingCount = ratingCount {
                    HStack {
                        RatingView(rating: rating)
                        Text("(\(ratingCount) ratings)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Price (Conditional Display)
                if let price = price {
                    Text(String(format: "$%.2f", price))
                        .font(.title3)
                        .fontWeight(.semibold)
                    if let priceDisclaimer = priceDisclaimer {
                        Text(priceDisclaimer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // "Slide to Rate" (Optional)
                HStack {
                    Text("Slide to rate this product")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star")
                                .foregroundColor(.gray)
                        }
                    }
                    
                }
                .padding(.vertical, 8)
                Divider()
                // Actions Button (Example)
                Button(action: {
                    // Handle actions
                }) {
                    HStack {
                        Image(systemName: "ellipsis.circle") // Example icon
                        Text("Actions")
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                }
                .padding(.vertical, 8)
                
                //Similar Products Section
                HStack{
                    Text("Higher rating, same price range").font(.subheadline).foregroundColor(.green)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.top, 8)
                
                HStack{
                    Spacer()
                    Image("preworkout_example")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 70)
                }
                
                Button("Shop similar products"){
                    
                }.buttonStyle(.borderedProminent)
                    .tint(.black)
                    .padding(.top, 8)
                
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 3)
            .padding()

            Spacer() // Push content to the top
        }
        .background(Color(.systemGray6)) // Very light gray background
        .edgesIgnoringSafeArea(.top) // Extend background to top
    }
}

struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(rating) ? "star.fill" : (index < Int(ceil(rating)) && rating != Double(Int(rating)) ? "star.leadinghalf.fill" : "star"))
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ProductInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductInfoView(productImage: Image("preworkout_example"), productName: "C4 Sport Pre-Workout Powder", productDetails: "Fruit Punch", rating: 3.8, ratingCount: 87, price: 10.07, priceDisclaimer: "Based on prices from Vivino users")
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
        ProductInfoView(productImage: Image("preworkout_example"), productName: "C4 Sport", productDetails: "Fruit Punch", rating: 4.5, ratingCount: 120, price: 19.99, priceDisclaimer: nil)
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
    }
}