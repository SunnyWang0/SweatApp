//
//  ContentView.swift
//  Sweat
//
//  Created by Sunny Wang on 1/18/25.
//

import SwiftUI
import CoreData

struct StatsCard: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        NavigationLink(destination: Text(title)) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .frame(width: 30)
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct RecentScanCard: View {
    let supplement: Supplement
    
    var body: some View {
        VStack {
            if let imageUrl = supplement.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 120, height: 160)
                .clipped()
                .cornerRadius(8)
            } else {
                Color.gray
                    .frame(width: 120, height: 160)
                    .cornerRadius(8)
            }
            
            Text(supplement.name ?? "Unknown Supplement")
                .font(.caption)
                .lineLimit(2)
            Text("\(supplement.type ?? "")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    @FetchRequest(
        entity: Supplement.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplement.name, ascending: true)]
    ) private var supplements: FetchedResults<supplement>
    
    @FetchRequest(
        entity: Rating.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Rating.date, ascending: true)]
    ) private var ratings: FetchedResults<Rating>
    
    @FetchRequest(
        entity: Scan.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Scan.date, ascending: false)]
    ) private var recentScans: FetchedResults<Scan>

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Cards
                        VStack(spacing: 8) {
                            StatsCard(icon: "wineglass", title: "My Supplements", count: supplements.count)
                            StatsCard(icon: "star", title: "Ratings", count: ratings.count)
                            StatsCard(icon: "bookmark", title: "Wishlist", count: 0)
                            StatsCard(icon: "square.grid.3x3", title: "Cellar", count: 0)
                            StatsCard(icon: "shippingbox", title: "Orders", count: 0)
                        }
                        .padding(.horizontal)
                        
                        // Recent Scans
                        VStack(alignment: .leading) {
                            Text("Recent scans")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(recentScans.prefix(5)) { scan in
                                        if let supplement = scan.supplement {
                                            RecentScanCard(supplement: supplement)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {}) {
                                Image(systemName: "cart")
                            }
                            Button(action: {}) {
                                Image(systemName: "bell")
                            }
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0)
            
            Text("Camera")
                .tabItem {
                    Image(systemName: "camera")
                    Text("")
                }
                .tag(1)
            
            Text("Profile")
                .tabItem {
                    Image(systemName: "person")
                    Text("You")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
