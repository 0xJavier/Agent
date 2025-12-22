# The Composable Architecture (TCA) Patterns

Use TCA for apps requiring: predictable state management, comprehensive testing, complex side effects, or team consistency.

## Basic Reducer Pattern

```swift
import ComposableArchitecture

@Reducer
struct TaskList {
    @ObservableState
    struct State: Equatable {
        var tasks: IdentifiedArrayOf<Task> = []
        var isLoading = false
        @Presents var destination: Destination.State?
    }
    
    enum Action: ViewAction {
        case view(View)
        case tasksResponse(Result<[Task], Error>)
        case destination(PresentationAction<Destination.Action>)
        
        enum View {
            case onAppear
            case addButtonTapped
            case taskTapped(Task)
            case deleteTask(IndexSet)
        }
    }
    
    @Dependency(\.taskClient) var taskClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isLoading = true
                return .run { send in
                    await send(.tasksResponse(Result { try await taskClient.fetchAll() }))
                }
                
            case let .tasksResponse(.success(tasks)):
                state.isLoading = false
                state.tasks = IdentifiedArray(uniqueElements: tasks)
                return .none
                
            case let .tasksResponse(.failure(error)):
                state.isLoading = false
                // Handle error
                return .none
                
            case .view(.addButtonTapped):
                state.destination = .addTask(AddTask.State())
                return .none
                
            case let .view(.taskTapped(task)):
                state.destination = .detail(TaskDetail.State(task: task))
                return .none
                
            case let .view(.deleteTask(indexSet)):
                state.tasks.remove(atOffsets: indexSet)
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

// Destination reducer for navigation
extension TaskList {
    @Reducer
    enum Destination {
        case addTask(AddTask)
        case detail(TaskDetail)
    }
}
```

## View Integration

```swift
struct TaskListView: View {
    @Bindable var store: StoreOf<TaskList>
    
    var body: some View {
        List {
            ForEach(store.tasks) { task in
                TaskRow(task: task)
                    .onTapGesture { store.send(.view(.taskTapped(task))) }
            }
            .onDelete { store.send(.view(.deleteTask($0))) }
        }
        .overlay { if store.isLoading { ProgressView() } }
        .toolbar {
            Button("Add") { store.send(.view(.addButtonTapped)) }
        }
        .sheet(item: $store.scope(state: \.destination?.addTask, action: \.destination.addTask)) { store in
            AddTaskView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.destination?.detail, action: \.destination.detail)) { store in
            TaskDetailView(store: store)
        }
        .onAppear { store.send(.view(.onAppear)) }
    }
}
```

## Dependency Management

```swift
// Define the dependency
struct TaskClient {
    var fetchAll: @Sendable () async throws -> [Task]
    var create: @Sendable (Task) async throws -> Task
    var delete: @Sendable (Task.ID) async throws -> Void
}

// Live implementation
extension TaskClient: DependencyKey {
    static let liveValue = TaskClient(
        fetchAll: {
            let (data, _) = try await URLSession.shared.data(from: API.tasks)
            return try JSONDecoder().decode([Task].self, from: data)
        },
        create: { task in
            // Network request
        },
        delete: { id in
            // Network request
        }
    )
}

// Test implementation
extension TaskClient {
    static let testValue = TaskClient(
        fetchAll: { [Task(id: UUID(), title: "Test")] },
        create: { $0 },
        delete: { _ in }
    )
}

// Register
extension DependencyValues {
    var taskClient: TaskClient {
        get { self[TaskClient.self] }
        set { self[TaskClient.self] = newValue }
    }
}
```

## Testing TCA

```swift
import Testing
@testable import App

@Test func loadTasks() async {
    let store = TestStore(initialState: TaskList.State()) {
        TaskList()
    } withDependencies: {
        $0.taskClient.fetchAll = { [Task(id: UUID(), title: "Test")] }
    }
    
    await store.send(.view(.onAppear)) {
        $0.isLoading = true
    }
    
    await store.receive(\.tasksResponse.success) {
        $0.isLoading = false
        $0.tasks = [Task(id: UUID(), title: "Test")]
    }
}

@Test func deleteTask() async {
    let task = Task(id: UUID(), title: "Delete me")
    let store = TestStore(initialState: TaskList.State(tasks: [task])) {
        TaskList()
    }
    
    await store.send(.view(.deleteTask(IndexSet(integer: 0)))) {
        $0.tasks = []
    }
}
```

## When to Use TCA vs MVVM

**Choose TCA when:**
- Large team needs consistent patterns
- Complex state dependencies between features
- Extensive testing requirements
- Time-travel debugging needed
- Side effects need precise control

**Choose MVVM when:**
- Smaller app or team
- Rapid prototyping
- Team unfamiliar with functional patterns
- Simpler state management needs
