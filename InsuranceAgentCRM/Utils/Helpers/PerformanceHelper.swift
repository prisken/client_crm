import Foundation
import SwiftUI

// MARK: - Performance Helper
struct PerformanceHelper {
    
    // MARK: - Debounce
    static func debounce<T: Equatable>(
        _ value: T,
        delay: TimeInterval = 0.5,
        action: @escaping (T) -> Void
    ) -> T {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action(value)
        }
        return value
    }
    
    // MARK: - Throttle
    private static var throttleWorkItems: [String: DispatchWorkItem] = [:]
    
    static func throttle(
        key: String,
        delay: TimeInterval = 0.3,
        action: @escaping () -> Void
    ) {
        // Cancel previous work item
        throttleWorkItems[key]?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem {
            action()
            throttleWorkItems.removeValue(forKey: key)
        }
        
        throttleWorkItems[key] = workItem
        
        // Schedule execution
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    // MARK: - Memory Management
    static func optimizeMemoryUsage() {
        // Clear caches if memory pressure is high
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            URLCache.shared.removeAllCachedResponses()
        }
    }
    
    // MARK: - Background Processing
    static func performInBackground<T>(
        _ operation: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try operation()
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Performance View Modifier
struct PerformanceModifier: ViewModifier {
    let onAppear: (() -> Void)?
    let onDisappear: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                onAppear?()
            }
            .onDisappear {
                onDisappear?()
            }
    }
}

// MARK: - View Extension for Performance
extension View {
    func performanceOptimized(
        onAppear: (() -> Void)? = nil,
        onDisappear: (() -> Void)? = nil
    ) -> some View {
        self.modifier(PerformanceModifier(
            onAppear: onAppear,
            onDisappear: onDisappear
        ))
    }
}

// MARK: - Lazy Loading Helper
struct LazyLoadingHelper {
    static func loadData<T>(
        page: Int = 0,
        pageSize: Int = 20,
        loadFunction: @escaping (Int, Int) throws -> [T],
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        PerformanceHelper.performInBackground({
            try loadFunction(page, pageSize)
        }, completion: completion)
    }
}

// MARK: - Cache Helper
struct CacheHelper {
    private static let cache = NSCache<NSString, AnyObject>()
    
    static func set<T: AnyObject>(_ object: T, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
    }
    
    static func get<T: AnyObject>(forKey key: String, type: T.Type) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    static func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    static func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - Image Optimization
struct ImageOptimizer {
    static func optimizeImage(_ image: UIImage, maxSize: CGSize = CGSize(width: 1024, height: 1024)) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
}

// MARK: - Network Optimization
struct NetworkOptimizer {
    static func optimizeRequest(_ request: inout URLRequest) {
        // Add compression
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        
        // Add caching headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Set timeout
        request.timeoutInterval = AppConstants.API.timeout
    }
}
