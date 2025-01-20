import Foundation
import UIKit

class DataManager {
    static let shared = DataManager()
    
    private let scansKey = "preworkout_scans"
    private let favoritesKey = "preworkout_favorites"
    private let imageDirectory = "preworkout_images"
    
    // Image cache to prevent constant disk reads
    private var imageCache: [UUID: UIImage] = [:]
    private let maxCacheSize = 20 // Maximum number of images to keep in memory
    private var cacheQueue: [UUID] = [] // Track order of cache entries
    
    private init() {
        createImageDirectoryIfNeeded()
    }
    
    // MARK: - Data Models
    
    struct StoredPreworkoutScan: Codable, Hashable {
        let id: UUID
        let name: String
        let ingredients: [String]
        let effects: [String]
        let qualities: [String: Int]
        let rating: Double
        let reviews: [String]
        
        init(from scan: PreworkoutScan) {
            self.id = scan.id
            self.name = scan.name
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
                frontImage: DataManager.shared.loadImage(for: self.id) ?? UIImage(),
                ingredients: self.ingredients,
                effects: self.effects,
                qualities: self.qualities,
                rating: self.rating,
                reviews: self.reviews
            )
        }
        
        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: StoredPreworkoutScan, rhs: StoredPreworkoutScan) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // MARK: - Public Methods
    
    func saveScan(_ scan: PreworkoutScan) {
        var scans = loadStoredScans()
        let storedScan = StoredPreworkoutScan(from: scan)
        
        // Update existing scan if it exists
        if let index = scans.firstIndex(where: { $0.id == scan.id }) {
            scans[index] = storedScan
        } else {
            scans.append(storedScan)
        }
        
        saveStoredScans(scans)
        saveImage(scan.frontImage, for: scan.id)
    }
    
    func loadScans() -> [PreworkoutScan] {
        return loadStoredScans().map { $0.toPreworkoutScan() }
    }
    
    func toggleFavorite(_ scan: PreworkoutScan) {
        var favorites = Set(loadStoredFavorites())
        let storedScan = StoredPreworkoutScan(from: scan)
        
        if favorites.contains(where: { $0.id == scan.id }) {
            favorites.remove(storedScan)
        } else {
            favorites.insert(storedScan)
        }
        
        saveStoredFavorites(Array(favorites))
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
    
    // MARK: - Image Storage
    
    private func createImageDirectoryIfNeeded() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let imageDirectoryURL = documentsDirectory.appendingPathComponent(imageDirectory)
        
        if !FileManager.default.fileExists(atPath: imageDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
        }
    }
    
    private func saveImage(_ image: UIImage, for id: UUID) {
        // Resize image if needed
        let maxDimension: CGFloat = 1024
        var finalImage = image
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                finalImage = resizedImage
            }
            UIGraphicsEndImageContext()
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageData = finalImage.jpegData(compressionQuality: 0.6) else { return }
        
        let imageURL = documentsDirectory.appendingPathComponent(imageDirectory).appendingPathComponent("\(id.uuidString).jpg")
        try? imageData.write(to: imageURL)
        
        // Update cache
        updateImageCache(id: id, image: finalImage)
    }
    
    private func loadImage(for id: UUID) -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[id] {
            // Move to front of cache queue
            if let index = cacheQueue.firstIndex(of: id) {
                cacheQueue.remove(at: index)
            }
            cacheQueue.append(id)
            return cachedImage
        }
        
        // Load from disk if not in cache
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let imageURL = documentsDirectory.appendingPathComponent(imageDirectory).appendingPathComponent("\(id.uuidString).jpg")
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else { return nil }
        
        // Update cache
        updateImageCache(id: id, image: image)
        return image
    }
    
    private func updateImageCache(id: UUID, image: UIImage) {
        // Remove oldest image if cache is full
        if cacheQueue.count >= maxCacheSize {
            if let oldestID = cacheQueue.first {
                imageCache.removeValue(forKey: oldestID)
                cacheQueue.removeFirst()
            }
        }
        
        // Add new image to cache
        imageCache[id] = image
        cacheQueue.append(id)
    }
} 