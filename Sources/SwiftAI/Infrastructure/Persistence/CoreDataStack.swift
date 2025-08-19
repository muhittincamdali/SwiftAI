//
//  CoreDataStack.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import CoreData
import Combine

/// Enterprise-grade Core Data stack with advanced features and security
public final class CoreDataStack: ObservableObject, CoreDataStackProtocol {
    
    // MARK: - Public Properties
    
    @Published public private(set) var isReady: Bool = false
    @Published public private(set) var syncStatus: SyncStatus = .idle
    @Published public private(set) var migrationProgress: Double = 0.0
    
    public let modelName: String
    public let storeType: StoreType
    
    // MARK: - Core Data Stack Components
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = createPersistentContainer()
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
    
    // MARK: - Private Properties
    
    private let logger: LoggerProtocol
    private let encryptionManager: EncryptionManagerProtocol
    private let performanceMonitor: PerformanceMonitorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let operationQueue = OperationQueue()
    private let syncQueue = DispatchQueue(label: "com.swiftai.coredata.sync", qos: .utility)
    
    // Configuration
    private let configuration: CoreDataConfiguration
    private var migrationObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    public init(
        modelName: String,
        storeType: StoreType = .sqlite,
        configuration: CoreDataConfiguration = CoreDataConfiguration(),
        logger: LoggerProtocol = Logger.shared,
        encryptionManager: EncryptionManagerProtocol = EncryptionManager(),
        performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor.shared
    ) {
        self.modelName = modelName
        self.storeType = storeType
        self.configuration = configuration
        self.logger = logger
        self.encryptionManager = encryptionManager
        self.performanceMonitor = performanceMonitor
        
        configureOperationQueue()
        setupNotificationObservers()
        
        if configuration.autoInitialize {
            initializeStack()
        }
    }
    
    deinit {
        tearDown()
    }
    
    // MARK: - Stack Management
    
    /// Initializes the Core Data stack
    public func initializeStack() {
        logger.info("Initializing Core Data stack: \(modelName)")
        
        performanceMonitor.measure(operation: "coredata_initialization") {
            do {
                _ = persistentContainer // This triggers lazy initialization
                setupViewContext()
                isReady = true
                logger.info("Core Data stack initialized successfully")
            } catch {
                logger.error("Core Data stack initialization failed: \(error.localizedDescription)")
                isReady = false
            }
        }
    }
    
    /// Safely tears down the Core Data stack
    public func tearDown() {
        logger.info("Tearing down Core Data stack")
        
        // Save any pending changes
        saveContextIfNeeded(viewContext)
        
        // Cancel operations
        operationQueue.cancelAllOperations()
        cancellables.removeAll()
        
        // Remove observers
        if let observer = migrationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        isReady = false
        logger.info("Core Data stack torn down")
    }
    
    // MARK: - Context Management
    
    /// Creates a new background context for concurrent operations
    /// - Returns: Configured background context
    public func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = configuration.mergePolicy
        context.automaticallyMergesChangesFromParent = true
        context.shouldDeleteInaccessibleFaults = true
        
        if configuration.enableUndoManager {
            context.undoManager = UndoManager()
        }
        
        return context
    }
    
    /// Creates a child context of the main view context
    /// - Returns: Child context
    public func createChildContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = viewContext
        context.mergePolicy = configuration.mergePolicy
        
        if configuration.enableUndoManager {
            context.undoManager = UndoManager()
        }
        
        return context
    }
    
    // MARK: - Save Operations
    
    /// Saves the view context if it has changes
    public func saveViewContext() {
        saveContextIfNeeded(viewContext)
    }
    
    /// Saves a specific context if it has changes
    /// - Parameter context: Context to save
    public func saveContext(_ context: NSManagedObjectContext) {
        saveContextIfNeeded(context)
    }
    
    /// Performs a save operation with error handling and performance monitoring
    /// - Parameter context: Context to save
    public func saveContextIfNeeded(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        performanceMonitor.measure(operation: "coredata_save") {
            context.performAndWait {
                do {
                    try context.save()
                    logger.debug("Context saved successfully")
                } catch {
                    logger.error("Failed to save context: \(error.localizedDescription)")
                    
                    // Handle save errors gracefully
                    handleSaveError(error, in: context)
                }
            }
        }
    }
    
    /// Performs a background save operation
    /// - Parameters:
    ///   - block: Operation to perform in background context
    ///   - completion: Completion handler called on main queue
    public func performBackgroundSave(
        _ block: @escaping (NSManagedObjectContext) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        let context = createBackgroundContext()
        
        context.perform {
            do {
                block(context)
                
                if context.hasChanges {
                    try context.save()
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                self.logger.error("Background save failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Performs a fetch request with performance monitoring
    /// - Parameters:
    ///   - request: Fetch request to execute
    ///   - context: Context to use for fetching (defaults to view context)
    /// - Returns: Fetch results
    /// - Throws: Core Data errors
    public func fetch<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        in context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        let fetchContext = context ?? viewContext
        
        return try performanceMonitor.measure(operation: "coredata_fetch") {
            try fetchContext.fetch(request)
        }
    }
    
    /// Performs a count request with performance monitoring
    /// - Parameters:
    ///   - request: Fetch request to count
    ///   - context: Context to use for counting (defaults to view context)
    /// - Returns: Object count
    /// - Throws: Core Data errors
    public func count<T: NSManagedObject>(
        for request: NSFetchRequest<T>,
        in context: NSManagedObjectContext? = nil
    ) throws -> Int {
        let fetchContext = context ?? viewContext
        
        return try performanceMonitor.measure(operation: "coredata_count") {
            try fetchContext.count(for: request)
        }
    }
    
    /// Executes a fetch request and returns the first result
    /// - Parameters:
    ///   - request: Fetch request to execute
    ///   - context: Context to use for fetching (defaults to view context)
    /// - Returns: First result or nil
    /// - Throws: Core Data errors
    public func fetchFirst<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        in context: NSManagedObjectContext? = nil
    ) throws -> T? {
        let fetchContext = context ?? viewContext
        request.fetchLimit = 1
        
        let results = try fetch(request, in: fetchContext)
        return results.first
    }
    
    // MARK: - Batch Operations
    
    /// Performs a batch delete operation
    /// - Parameters:
    ///   - request: Batch delete request
    ///   - context: Context to use (defaults to background context)
    /// - Returns: Batch delete result
    /// - Throws: Core Data errors
    public func batchDelete(
        _ request: NSBatchDeleteRequest,
        in context: NSManagedObjectContext? = nil
    ) throws -> NSBatchDeleteResult {
        let deleteContext = context ?? createBackgroundContext()
        
        return try performanceMonitor.measure(operation: "coredata_batch_delete") {
            let result = try deleteContext.execute(request) as! NSBatchDeleteResult
            
            // Merge changes to view context
            if let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
            }
            
            return result
        }
    }
    
    /// Performs a batch update operation
    /// - Parameters:
    ///   - request: Batch update request
    ///   - context: Context to use (defaults to background context)
    /// - Returns: Batch update result
    /// - Throws: Core Data errors
    public func batchUpdate(
        _ request: NSBatchUpdateRequest,
        in context: NSManagedObjectContext? = nil
    ) throws -> NSBatchUpdateResult {
        let updateContext = context ?? createBackgroundContext()
        
        return try performanceMonitor.measure(operation: "coredata_batch_update") {
            let result = try updateContext.execute(request) as! NSBatchUpdateResult
            
            // Merge changes to view context
            if let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSUpdatedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
            }
            
            return result
        }
    }
    
    // MARK: - Migration Support
    
    /// Checks if migration is needed
    /// - Returns: True if migration is required
    public func migrationNeeded() -> Bool {
        guard let storeURL = storeURL else { return false }
        
        do {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: storeType.coreDataType,
                at: storeURL,
                options: nil
            )
            
            return !managedObjectModel.isConfiguration(
                withName: nil,
                compatibleWithStoreMetadata: sourceMetadata
            )
        } catch {
            logger.error("Failed to check migration status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Performs manual migration if needed
    /// - Parameter completion: Completion handler with migration result
    public func performMigrationIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        guard migrationNeeded() else {
            completion(.success(()))
            return
        }
        
        logger.info("Starting Core Data migration")
        migrationProgress = 0.0
        
        operationQueue.addOperation {
            do {
                try self.performMigration()
                
                DispatchQueue.main.async {
                    self.migrationProgress = 1.0
                    self.logger.info("Core Data migration completed successfully")
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    self.logger.error("Core Data migration failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Data Export/Import
    
    /// Exports data to JSON format
    /// - Parameters:
    ///   - entityName: Name of entity to export
    ///   - predicate: Optional predicate to filter data
    /// - Returns: JSON data
    /// - Throws: Export errors
    public func exportToJSON(
        entityName: String,
        predicate: NSPredicate? = nil
    ) throws -> Data {
        return try performanceMonitor.measure(operation: "coredata_export") {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = predicate
            
            let objects = try fetch(request)
            let dictionaries = objects.map { $0.dictionaryWithValues(forKeys: Array($0.entity.attributesByName.keys)) }
            
            return try JSONSerialization.data(withJSONObject: dictionaries, options: .prettyPrinted)
        }
    }
    
    /// Imports data from JSON format
    /// - Parameters:
    ///   - data: JSON data to import
    ///   - entityName: Name of entity to create objects for
    /// - Throws: Import errors
    public func importFromJSON(
        data: Data,
        entityName: String
    ) throws {
        try performanceMonitor.measure(operation: "coredata_import") {
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw CoreDataError.invalidImportData
            }
            
            performBackgroundSave { context in
                guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
                    self.logger.error("Entity not found: \(entityName)")
                    return
                }
                
                for dictionary in jsonArray {
                    let object = NSManagedObject(entity: entity, insertInto: context)
                    object.setValuesForKeys(dictionary)
                }
                
                self.logger.info("Imported \(jsonArray.count) objects for entity: \(entityName)")
            }
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Gets Core Data performance statistics
    /// - Returns: Performance statistics
    public func getPerformanceStatistics() -> CoreDataStatistics {
        return CoreDataStatistics(
            isReady: isReady,
            syncStatus: syncStatus,
            pendingChanges: viewContext.hasChanges,
            registeredObjectsCount: viewContext.registeredObjects.count,
            insertedObjectsCount: viewContext.insertedObjects.count,
            updatedObjectsCount: viewContext.updatedObjects.count,
            deletedObjectsCount: viewContext.deletedObjects.count
        )
    }
    
    // MARK: - Private Methods
    
    private func createPersistentContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        
        // Configure store description
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.type = storeType.coreDataType
        storeDescription?.shouldMigrateStoreAutomatically = configuration.automaticMigration
        storeDescription?.shouldInferMappingModelAutomatically = configuration.inferMappingModel
        
        // Configure encryption if enabled
        if configuration.enableEncryption {
            configureEncryption(for: storeDescription)
        }
        
        // Set store URL
        if let url = storeURL {
            storeDescription?.url = url
        }
        
        // Load persistent stores
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                self?.handleStoreLoadError(error)
            } else {
                self?.logger.info("Persistent store loaded successfully")
            }
        }
        
        return container
    }
    
    private var managedObjectModel: NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to locate or load Core Data model: \(modelName)")
        }
        return model
    }
    
    private var storeURL: URL? {
        switch storeType {
        case .sqlite:
            return URL.documentsDirectory.appendingPathComponent("\(modelName).sqlite")
        case .binary:
            return URL.documentsDirectory.appendingPathComponent("\(modelName).store")
        case .inMemory:
            return nil
        }
    }
    
    private func setupViewContext() {
        viewContext.mergePolicy = configuration.mergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        
        if configuration.enableUndoManager {
            viewContext.undoManager = UndoManager()
        }
        
        // Set up automatic saves
        if configuration.autoSaveInterval > 0 {
            setupAutoSave()
        }
    }
    
    private func setupAutoSave() {
        Timer.publish(every: configuration.autoSaveInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.saveViewContext()
            }
            .store(in: &cancellables)
    }
    
    private func configureOperationQueue() {
        operationQueue.maxConcurrentOperationCount = 3
        operationQueue.qualityOfService = .utility
    }
    
    private func setupNotificationObservers() {
        // Observe context save notifications
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] notification in
                self?.handleContextDidSave(notification)
            }
            .store(in: &cancellables)
        
        // Observe memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func handleContextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        
        // Don't merge changes from the main context to itself
        if context !== viewContext {
            viewContext.perform {
                self.viewContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
    
    private func handleMemoryWarning() {
        logger.warning("Memory warning received, refreshing Core Data contexts")
        
        viewContext.perform {
            self.viewContext.refreshAllObjects()
        }
    }
    
    private func handleSaveError(_ error: Error, in context: NSManagedObjectContext) {
        // Handle specific Core Data errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSValidationErrorCode:
                logger.error("Validation error during save: \(nsError.localizedDescription)")
            case NSManagedObjectConstraintMergeErrorCode:
                logger.error("Constraint merge error during save: \(nsError.localizedDescription)")
            default:
                logger.error("Unknown Core Data error during save: \(nsError.localizedDescription)")
            }
        }
        
        // Rollback changes on error
        context.rollback()
    }
    
    private func handleStoreLoadError(_ error: Error) {
        // Handle store loading errors - potentially delete and recreate store
        logger.error("Store load error, attempting recovery: \(error.localizedDescription)")
        
        if configuration.deleteStoreOnLoadError {
            deleteAndRecreateStore()
        }
    }
    
    private func deleteAndRecreateStore() {
        guard let storeURL = storeURL else { return }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            logger.info("Deleted corrupted store, will recreate")
            
            // Reinitialize the stack
            initializeStack()
        } catch {
            logger.error("Failed to delete corrupted store: \(error.localizedDescription)")
        }
    }
    
    private func configureEncryption(for storeDescription: NSPersistentStoreDescription?) {
        // Configure store-level encryption
        // This would integrate with the EncryptionManager for key management
        logger.info("Configuring Core Data encryption")
        
        // Set file protection level
        storeDescription?.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
    }
    
    private func performMigration() throws {
        // Implement progressive migration logic
        // This would handle step-by-step migration for complex model changes
        logger.info("Performing Core Data migration")
        
        // Migration implementation would go here
        // For now, we'll rely on automatic lightweight migration
    }
}

// MARK: - Supporting Types

public enum StoreType {
    case sqlite
    case binary
    case inMemory
    
    var coreDataType: String {
        switch self {
        case .sqlite:
            return NSSQLiteStoreType
        case .binary:
            return NSBinaryStoreType
        case .inMemory:
            return NSInMemoryStoreType
        }
    }
}

public enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

public struct CoreDataConfiguration {
    public let automaticMigration: Bool
    public let inferMappingModel: Bool
    public let enableEncryption: Bool
    public let enableUndoManager: Bool
    public let autoSaveInterval: TimeInterval
    public let deleteStoreOnLoadError: Bool
    public let autoInitialize: Bool
    public let mergePolicy: NSMergePolicy
    
    public init(
        automaticMigration: Bool = true,
        inferMappingModel: Bool = true,
        enableEncryption: Bool = true,
        enableUndoManager: Bool = false,
        autoSaveInterval: TimeInterval = 30.0,
        deleteStoreOnLoadError: Bool = false,
        autoInitialize: Bool = true,
        mergePolicy: NSMergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    ) {
        self.automaticMigration = automaticMigration
        self.inferMappingModel = inferMappingModel
        self.enableEncryption = enableEncryption
        self.enableUndoManager = enableUndoManager
        self.autoSaveInterval = autoSaveInterval
        self.deleteStoreOnLoadError = deleteStoreOnLoadError
        self.autoInitialize = autoInitialize
        self.mergePolicy = mergePolicy
    }
}

public struct CoreDataStatistics {
    public let isReady: Bool
    public let syncStatus: SyncStatus
    public let pendingChanges: Bool
    public let registeredObjectsCount: Int
    public let insertedObjectsCount: Int
    public let updatedObjectsCount: Int
    public let deletedObjectsCount: Int
    
    public init(
        isReady: Bool,
        syncStatus: SyncStatus,
        pendingChanges: Bool,
        registeredObjectsCount: Int,
        insertedObjectsCount: Int,
        updatedObjectsCount: Int,
        deletedObjectsCount: Int
    ) {
        self.isReady = isReady
        self.syncStatus = syncStatus
        self.pendingChanges = pendingChanges
        self.registeredObjectsCount = registeredObjectsCount
        self.insertedObjectsCount = insertedObjectsCount
        self.updatedObjectsCount = updatedObjectsCount
        self.deletedObjectsCount = deletedObjectsCount
    }
}

// MARK: - Protocol Definition

public protocol CoreDataStackProtocol {
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    
    func initializeStack()
    func tearDown()
    func saveViewContext()
    func saveContext(_ context: NSManagedObjectContext)
    func createBackgroundContext() -> NSManagedObjectContext
    func createChildContext() -> NSManagedObjectContext
    func performBackgroundSave(_ block: @escaping (NSManagedObjectContext) -> Void, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Error Types

public enum CoreDataError: LocalizedError {
    case stackNotReady
    case invalidImportData
    case migrationFailed(Error)
    case storeLoadFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .stackNotReady:
            return "Core Data stack is not ready"
        case .invalidImportData:
            return "Invalid import data format"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .storeLoadFailed(let error):
            return "Store load failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - UIKit Import for Memory Warning

#if canImport(UIKit)
import UIKit
#endif