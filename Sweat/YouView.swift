import SwiftUI

struct PreworkoutScan: Identifiable, Hashable {
    let id: UUID
    let name: String
    let frontImage: UIImage
    let ingredients: [String]
    let effects: [String]
    let qualities: [String: Int]
    let rating: Double
    let reviews: [String]
    
    static func == (lhs: PreworkoutScan, rhs: PreworkoutScan) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class HomeViewModel: ObservableObject {
    @Published var pastScans: [PreworkoutScan] = []
    @Published var favorites: [PreworkoutScan] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        pastScans = DataManager.shared.loadScans()
        favorites = DataManager.shared.loadFavorites()
    }
    
    func toggleFavorite(_ scan: PreworkoutScan) {
        DataManager.shared.toggleFavorite(scan)
        loadData()
    }
    
    func isFavorite(_ scan: PreworkoutScan) -> Bool {
        return DataManager.shared.isFavorite(scan)
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedTab) {
                    Text("Past Scans").tag(0)
                    Text("Favorites").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    PreworkoutList(items: viewModel.pastScans, emptyMessage: "No past scans yet", viewModel: viewModel)
                } else {
                    PreworkoutList(items: viewModel.favorites, emptyMessage: "No favorites yet", viewModel: viewModel)
                }
            }
            .navigationTitle("Home")
        }
    }
}

struct PreworkoutList: View {
    let items: [PreworkoutScan]
    let emptyMessage: String
    let viewModel: HomeViewModel
    
    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(emptyMessage, systemImage: "sparkles")
        } else {
            List(items) { item in
                NavigationLink(destination: PreworkoutDetailView(scan: item, viewModel: viewModel)) {
                    PreworkoutRow(scan: item)
                }
            }
        }
    }
}

struct PreworkoutRow: View {
    let scan: PreworkoutScan
    
    var body: some View {
        HStack(spacing: 15) {
            Image(uiImage: scan.frontImage)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", scan.rating))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct PreworkoutDetailView: View {
    let scan: PreworkoutScan
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with image and rating
                HStack(alignment: .top, spacing: 20) {
                    Image(uiImage: scan.frontImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scan.name)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", scan.rating))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Favorite Button
                Button(action: {
                    viewModel.toggleFavorite(scan)
                }) {
                    Label(
                        viewModel.isFavorite(scan) ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: viewModel.isFavorite(scan) ? "heart.fill" : "heart"
                    )
                    .foregroundColor(viewModel.isFavorite(scan) ? .red : .blue)
                }
                .padding(.horizontal)
                
                // Qualities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Qualities")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(scan.qualities.keys.sorted()), id: \.self) { key in
                        QualityBar(label: key, value: scan.qualities[key] ?? 0)
                    }
                }
                
                // Ingredients and Effects
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients & Effects")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(scan.ingredients.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scan.ingredients[index])
                                .font(.subheadline)
                                .bold()
                            Text(scan.effects[index])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if index < scan.ingredients.count - 1 {
                            Divider()
                        }
                    }
                }
                
                // Reviews
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reviews")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if scan.reviews.isEmpty {
                        Text("No reviews yet")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(scan.reviews, id: \.self) { review in
                            Text(review)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QualityBar: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.capitalized)
                .font(.subheadline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.1)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                        .foregroundColor(.blue)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 