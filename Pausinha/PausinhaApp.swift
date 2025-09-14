//
//  PausinhaApp.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 12/09/25.
//

import SwiftUI
import SwiftData

@main
struct PausinhaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UserProfile.self,
            PublicProfile.self,
        ])
        
        do {
            print("PausinhaApp: Creating ModelContainer with schema: \(schema)")
            
            // Try without CloudKit first to isolate the issue
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("PausinhaApp: ✅ ModelContainer created successfully")
            return container
        } catch let error as DecodingError {
            print("PausinhaApp: ❌ DecodingError creating ModelContainer: \(error)")
            print("PausinhaApp: DecodingError details: \(error.localizedDescription)")
            // Fallback to in-memory storage
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                print("PausinhaApp: ❌ Fallback ModelContainer creation failed: \(error)")
                fatalError("Fallback ModelContainer creation failed: \(error)")
            }
        } catch {
            print("PausinhaApp: ❌ Error creating ModelContainer: \(error)")
            print("PausinhaApp: Error type: \(type(of: error))")
            print("PausinhaApp: Error description: \(error.localizedDescription)")
            
            // Try to get more detailed error information
            if let swiftDataError = error as? any LocalizedError {
                print("PausinhaApp: SwiftData Error reason: \(swiftDataError.errorDescription ?? "Unknown")")
                print("PausinhaApp: SwiftData Error suggestion: \(swiftDataError.recoverySuggestion ?? "None")")
            }
            
            // Fallback to in-memory storage
            do {
                print("PausinhaApp: 🔄 Attempting fallback to in-memory storage")
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                print("PausinhaApp: ✅ Fallback ModelContainer created successfully")
                return container
            } catch {
                print("PausinhaApp: ❌ Could not create ModelContainer even with fallback: \(error)")
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
