import Foundation
import UIKit

class DataManager {
    static let shared = DataManager()
    
    private let scansKey = "preworkout_scans"
    private let favoritesKey = "preworkout_favorites"
    
    private init() {}
    
    // MARK: - Data Models
    
    struct StoredPreworkoutScan: Codable {
        let id: UUID
        let name: String
        let frontImageData: Data
        let ingredients: [String]
        let effects: [String]
        let qualities: [String: Int]
        let rating: Double
        let reviews: [String]
        
        init(from scan: PreworkoutScan) {
            self.id = scan.id
            self.name = scan.name
            self.frontImageData = scan.frontImage.jpegData(compressionQuality: 0.8) ?? Data()
            self.ingredients = scan.ingredients
            self.effects = scan.effects
            self.qualities = scan.qualities
            self.rating = scan.rating
            self.reviews = scan.reviews
        }
        
        func toPreworkoutScan() -> PreworkoutScan {
            return PreworkoutScan(
                id: self.id,
                name: self.name,
                frontImage: UIImage(data: self.frontImageData) ?? UIImage(),
                ingredients: self.ingredients,
                effects: self.effects,
                qualities: self.qualities,
                rating: self.rating,
                reviews: self.reviews
            )
        }
    }
    
    // MARK: - Public Methods
    
    func saveScan(_ scan: PreworkoutScan) {
        var scans = loadStoredScans()
        let storedScan = StoredPreworkoutScan(from: scan)
        scans.append(storedScan)
        saveStoredScans(scans)
    }
    
    func loadScans() -> [PreworkoutScan] {
        return loadStoredScans().map { $0.toPreworkoutScan() }
    }
    
    func toggleFavorite(_ scan: PreworkoutScan) {
        var favorites = loadStoredFavorites()
        if let index = favorites.firstIndex(where: { $0.id == scan.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(StoredPreworkoutScan(from: scan))
        }
        saveStoredFavorites(favorites)
    }
    
    func loadFavorites() -> [PreworkoutScan] {
        return loadStoredFavorites().map { $0.toPreworkoutScan() }
    }
    
    func isFavorite(_ scan: PreworkoutScan) -> Bool {
        return loadStoredFavorites().contains(where: { $0.id == scan.id })
    }
    
    // MARK: - Private Methods
    
    private func loadStoredScans() -> [StoredPreworkoutScan] {
        guard let data = UserDefaults.standard.data(forKey: scansKey) else { return [] }
        return (try? JSONDecoder().decode([StoredPreworkoutScan].self, from: data)) ?? []
    }
    
    private func saveStoredScans(_ scans: [StoredPreworkoutScan]) {
        guard let data = try? JSONEncoder().encode(scans) else { return }
        UserDefaults.standard.set(data, forKey: scansKey)
    }
    
    private func loadStoredFavorites() -> [StoredPreworkoutScan] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        return (try? JSONDecoder().decode([StoredPreworkoutScan].self, from: data)) ?? []
    }
    
    private func saveStoredFavorites(_ favorites: [StoredPreworkoutScan]) {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
} 