# Core Data with SwiftUI

## Table of Contents

1. [Setup](#setup)
2. [Basic CRUD Operations](#basic-crud-operations)
3. [SwiftUI Integration](#swiftui-integration)
4. [Relationships](#relationships)
5. [Background Operations](#background-operations)
6. [Migration](#migration)

## Setup

### Data Model

Create `.xcdatamodeld` file in Xcode with entities. Example `Task` entity:

| Attribute | Type |
|-----------|------|
| id | UUID |
| title | String |
| isCompleted | Boolean |
| createdAt | Date |
| priority | Int16 |

### Persistence Controller

```swift
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    
    // Preview helper for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data
        for i in 0..<10 {
            let task = TaskEntity(context: viewContext)
            task.id = UUID()
            task.title = "Sample Task \(i)"
            task.isCompleted = i % 2 == 0
            task.createdAt = Date()
            task.priority = Int16(i % 3)
        }
        
        try? viewContext.save()
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
}
```

### App Setup

```swift
@main
struct MyApp: App {
    let persistence = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
        }
    }
}
```

## Basic CRUD Operations

### Create

```swift
func createTask(title: String, priority: Int) {
    let context = PersistenceController.shared.viewContext
    let task = TaskEntity(context: context)
    task.id = UUID()
    task.title = title
    task.isCompleted = false
    task.createdAt = Date()
    task.priority = Int16(priority)
    
    PersistenceController.shared.save()
}
```

### Read with FetchRequest

```swift
struct TaskListView: View {
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.priority, order: .reverse),
            SortDescriptor(\.createdAt, order: .reverse)
        ],
        predicate: NSPredicate(format: "isCompleted == %@", NSNumber(value: false)),
        animation: .default
    )
    private var tasks: FetchedResults<TaskEntity>
    
    var body: some View {
        List(tasks) { task in
            TaskRow(task: task)
        }
    }
}
```

### Dynamic FetchRequest

```swift
struct FilteredTasksView: View {
    @State private var showCompleted = false
    
    var body: some View {
        FilteredList(showCompleted: showCompleted)
    }
}

struct FilteredList: View {
    @FetchRequest var tasks: FetchedResults<TaskEntity>
    
    init(showCompleted: Bool) {
        let predicate = showCompleted 
            ? NSPredicate(value: true)
            : NSPredicate(format: "isCompleted == NO")
        
        _tasks = FetchRequest(
            sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
            predicate: predicate
        )
    }
    
    var body: some View {
        List(tasks) { task in
            TaskRow(task: task)
        }
    }
}
```

### Update

```swift
func toggleCompletion(for task: TaskEntity) {
    task.isCompleted.toggle()
    PersistenceController.shared.save()
}
```

### Delete

```swift
func deleteTask(_ task: TaskEntity) {
    let context = PersistenceController.shared.viewContext
    context.delete(task)
    PersistenceController.shared.save()
}

// In SwiftUI List
.onDelete { indexSet in
    indexSet.map { tasks[$0] }.forEach(deleteTask)
}
```

## SwiftUI Integration

### Section-Based FetchRequest

```swift
@SectionedFetchRequest(
    sectionIdentifier: \.prioritySection,
    sortDescriptors: [
        SortDescriptor(\.priority, order: .reverse),
        SortDescriptor(\.title)
    ]
)
private var sectionedTasks: SectionedFetchResults<String, TaskEntity>

// Add computed property to entity extension
extension TaskEntity {
    @objc var prioritySection: String {
        switch priority {
        case 2: return "High"
        case 1: return "Medium"
        default: return "Low"
        }
    }
}

var body: some View {
    List {
        ForEach(sectionedTasks) { section in
            Section(header: Text(section.id)) {
                ForEach(section) { task in
                    TaskRow(task: task)
                }
            }
        }
    }
}
```

### Binding to Core Data Objects

```swift
struct TaskEditView: View {
    @ObservedObject var task: TaskEntity
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        Form {
            TextField("Title", text: Binding(
                get: { task.title ?? "" },
                set: { task.title = $0 }
            ))
            
            Toggle("Completed", isOn: $task.isCompleted)
            
            Picker("Priority", selection: $task.priority) {
                Text("Low").tag(Int16(0))
                Text("Medium").tag(Int16(1))
                Text("High").tag(Int16(2))
            }
        }
        .onDisappear {
            try? context.save()
        }
    }
}
```

## Relationships

### One-to-Many

```swift
// Entity: Project (has many tasks)
// Entity: TaskEntity (belongs to project)

struct ProjectDetailView: View {
    @ObservedObject var project: Project
    
    var sortedTasks: [TaskEntity] {
        (project.tasks as? Set<TaskEntity>)?
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            ?? []
    }
    
    var body: some View {
        List(sortedTasks) { task in
            TaskRow(task: task)
        }
    }
}

// Creating with relationship
func createTask(in project: Project, title: String) {
    let context = PersistenceController.shared.viewContext
    let task = TaskEntity(context: context)
    task.id = UUID()
    task.title = title
    task.project = project  // Set relationship
    
    PersistenceController.shared.save()
}
```

## Background Operations

### Background Save

```swift
func importTasks(_ data: [TaskData]) async {
    let context = PersistenceController.shared.newBackgroundContext()
    
    await context.perform {
        for item in data {
            let task = TaskEntity(context: context)
            task.id = item.id
            task.title = item.title
            task.isCompleted = item.isCompleted
            task.createdAt = item.createdAt
            task.priority = Int16(item.priority)
        }
        
        do {
            try context.save()
        } catch {
            print("Background save error: \(error)")
        }
    }
}
```

### Batch Delete

```swift
func deleteAllCompletedTasks() async {
    let context = PersistenceController.shared.newBackgroundContext()
    
    await context.perform {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == YES")
        
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDelete.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []
            
            // Merge changes to view context
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [PersistenceController.shared.viewContext]
            )
        } catch {
            print("Batch delete error: \(error)")
        }
    }
}
```

## Migration

### Lightweight Migration (Automatic)

For simple changes (add attribute, rename, etc.), Core Data handles migration automatically:

```swift
let description = NSPersistentStoreDescription()
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
container.persistentStoreDescriptions = [description]
```

### Custom Migration

For complex changes, create mapping model:

1. Create new model version in Xcode
2. Create mapping model (.xcmappingmodel)
3. Define custom migration policies if needed:

```swift
class TaskMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource source: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        try super.createDestinationInstances(forSource: source, in: mapping, manager: manager)
        
        guard let destination = manager.destinationInstances(
            forEntityMappingName: mapping.name,
            sourceInstances: [source]
        ).first else { return }
        
        // Custom transformation logic
        if let oldPriority = source.value(forKey: "priorityString") as? String {
            let newPriority: Int16 = switch oldPriority {
                case "high": 2
                case "medium": 1
                default: 0
            }
            destination.setValue(newPriority, forKey: "priority")
        }
    }
}
```
