# Swift 6.2 @Observable Patterns

## @Observable vs ObservableObject

Swift 6.2 introduces `@Observable` macro replacing `ObservableObject`:

```swift
// Swift 6.2 - Use this
@Observable
final class AppState {
    var orders: [Order] = []
    var isRefreshing: Bool = false
    var selectedOrderId: OrderId?
}

// Old pattern - Don't use
class AppState: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isRefreshing: Bool = false
    @Published var selectedOrderId: OrderId?
}
```

## No ViewModel Layer

Views consume domain models directly:

```swift
// Direct domain model consumption
struct OrderListView: View {
    let orders: [Order]  // Domain models

    var body: some View {
        List(orders, id: \.id) { order in
            OrderRow(order: order)
        }
    }
}

struct OrderRow: View {
    let order: Order  // Domain model directly

    var body: some View {
        HStack {
            Text(order.status.displayName)
            Spacer()
            Text(order.totalAmount, format: .currency(code: "USD"))
        }
        .foregroundStyle(order.status.displayColor)
    }
}
```

## @State with @Observable

Use `@State` to own `@Observable` objects in views:

```swift
@main
struct MyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
    }
}
```

## Sendable Conformance

`@Observable` classes need `@unchecked Sendable` for actor isolation:

```swift
@Observable
public final class OrderState: @unchecked Sendable {
    public private(set) var orders: [Order] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: Error?

    public var selectedOrder: Order? {
        orders.first { $0.id == selectedOrderId }
    }

    private var selectedOrderId: OrderId?
}
```

## Computed Properties

Use computed properties for derived state:

```swift
@Observable
final class AppState {
    var orders: [Order] = []
    var filterStatus: OrderStatus?

    // Derived from orders - no @Published needed
    var filteredOrders: [Order] {
        guard let status = filterStatus else { return orders }
        return orders.filter { $0.status == status }
    }

    var pendingCount: Int {
        orders.filter { $0.status == .pending }.count
    }

    var hasOrders: Bool {
        !orders.isEmpty
    }

    var totalValue: Decimal {
        orders.reduce(0) { $0 + $1.totalAmount }
    }
}
```

## Environment with @Observable

Pass `@Observable` objects through environment when needed:

```swift
struct ContentView: View {
    let appState: AppState

    var body: some View {
        NavigationStack {
            OrderListView()
        }
        .environment(appState)
    }
}

struct OrderListView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        List(appState.filteredOrders, id: \.id) { order in
            NavigationLink(value: order) {
                OrderRow(order: order)
            }
        }
        .navigationDestination(for: Order.self) { order in
            OrderDetailView(order: order)
        }
    }
}
```

## Binding with @Observable

Use `@Bindable` for two-way bindings:

```swift
struct FilterView: View {
    @Bindable var appState: AppState

    var body: some View {
        Picker("Status", selection: $appState.filterStatus) {
            Text("All").tag(nil as OrderStatus?)
            ForEach(OrderStatus.allCases, id: \.self) { status in
                Text(status.displayName).tag(status as OrderStatus?)
            }
        }
    }
}
```

## Actor Integration

Combine `@Observable` with actors for thread-safe operations:

```swift
@Observable
final class OrderState: @unchecked Sendable {
    private(set) var orders: [Order] = []
    private(set) var isLoading: Bool = false

    private let book: OrderBook  // Actor

    init(book: OrderBook) {
        self.book = book
    }

    @MainActor
    func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            orders = try await book.all()
        } catch {
            // Handle error
        }
    }

    @MainActor
    func updateStatus(_ orderId: OrderId, to status: OrderStatus) async {
        do {
            try await book.updateStatus(orderId, to: status)
            // Refresh the specific order
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = try await book.getOrder(orderId)
            }
        } catch {
            // Handle error
        }
    }
}
```
