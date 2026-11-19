# TDD Test Patterns (Chicago School)

We follow **Chicago school TDD** (state-based testing):

| Chicago School (We Use This)          | London School (Avoid)                    |
|---------------------------------------|------------------------------------------|
| Test state changes and return values  | Test interactions between objects        |
| Mocks stub data, not verify calls     | Mocks verify method calls were made      |
| Focus on "what" (outcomes)            | Focus on "how" (behavior)                |
| Design emerges from tests             | Design upfront, tests verify design      |
| Fewer, coarser-grained tests          | Many fine-grained interaction tests      |

## Swift Testing Framework

Use `@Test` and `@Suite` instead of XCTest:

```swift
import Testing
import Foundation
@testable import App   // the module that holds Sources/Orders/

@Suite
struct OrderTests {
    @Test func `should let a pending order be cancelled`() {
        let order = Order(items: [], status: .pending)
        #expect(order.canBeCancelled == true)
    }
}
```

## Given-When-Then Structure

```swift
@Test func `should total an order from its items`() {
    // Given
    let order = Order(items: [
        OrderItem(price: 10, quantity: 2),
        OrderItem(price: 5, quantity: 1)
    ], status: .pending)

    // When
    let total = order.totalAmount

    // Then
    #expect(total == 25)
}
```

## Mocking with @Mockable (Chicago Style)

Define mockable protocols for external dependencies:

```swift
import Mockable

@Mockable
public protocol OrderRepository: Sendable {
    func all() async throws -> [Order]
    func fetch(id: OrderId) async throws -> Order
    func save(_ order: Order) async throws
}

@Mockable
public protocol HTTP: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
```

**Chicago school mock usage** - stub return values, verify resulting state:

```swift
import Mockable

@Suite
struct OrderBookTests {
    @Test func `should give back the order it was asked for`() async throws {
        // Given - STUB dependencies to return data
        let mockOrders = MockOrderRepository()
        let expectedOrder = Order(
            id: OrderId("123"),
            items: [OrderItem(price: 10, quantity: 1)],
            status: .pending
        )
        given(mockOrders).fetch(id: any()).willReturn(expectedOrder)

        let book = OrderBook(orders: mockOrders)

        // When
        let result = try await book.getOrder(OrderId("123"))

        // Then - verify STATE, not that methods were called
        #expect(result.status == .pending)
        #expect(result.totalAmount == 10)
        // AVOID: verify(mockOrders).fetch(id: any()).called(1)  // London school - don't do this
    }
}
```

**Key principle**: Use `given().willReturn()` to stub data. Avoid `verify().called()` for interactions.

## Domain Model Tests

Test state and computed properties:

```swift
@Suite
struct MoneyTests {
    @Test func `should add two amounts in the same currency`() {
        let money1 = Money(amount: 10, currency: .usd)
        let money2 = Money(amount: 5, currency: .usd)

        let result = money1.adding(money2)

        #expect(result.amount == 15)
        #expect(result.currency == .usd)
    }

    @Test func `should show an amount with its currency symbol`() {
        let money = Money(amount: 99.99, currency: .usd)

        #expect(money.formatted == "$99.99")
    }
}

@Suite
struct OrderStatusTests {
    @Test func `should need attention while pending`() {
        #expect(OrderStatus.pending.needsAttention == true)
    }

    @Test func `should be final once delivered`() {
        #expect(OrderStatus.delivered.isTerminal == true)
    }

    @Test func `should not need attention once shipped`() {
        #expect(OrderStatus.shipped.needsAttention == false)
    }
}
```

## Async Test Patterns

```swift
@Test func `should load an order when the API answers`() async throws {
    // Given
    let mockHTTP = MockHTTP()
    given(mockHTTP).request(any()).willReturn(
        OrderDTO(id: "123", status: "pending", items: [])
    )
    let orders = APIOrderRepository(http: mockHTTP)

    // When
    let order = try await orders.fetch(id: OrderId("123"))

    // Then
    #expect(order.id.value == "123")
    #expect(order.status == .pending)
}

@Test func `should fail when the network is down`() async {
    // Given
    let mockHTTP = MockHTTP()
    given(mockHTTP).request(any()).willThrow(NetworkError.connectionFailed)
    let orders = APIOrderRepository(http: mockHTTP)

    // When/Then
    await #expect(throws: OrdersError.networkError) {
        try await orders.fetch(id: OrderId("123"))
    }
}
```

## Actor Tests

```swift
@Suite
struct OrderBookTests {
    @Test func `should serve an order again without refetching it`() async throws {
        // Given
        let mockOrders = MockOrderRepository()
        let order = Order(id: OrderId("123"), items: [], status: .pending)
        given(mockOrders).fetch(id: any()).willReturn(order)

        let book = OrderBook(orders: mockOrders)

        // When - fetch twice
        let first = try await book.getOrder(OrderId("123"))
        let second = try await book.getOrder(OrderId("123"))

        // Then - both return same order (cached)
        #expect(first.id == second.id)
    }

    @Test func `should show the new status after an update`() async throws {
        // Given
        let mockOrders = MockOrderRepository()
        var order = Order(id: OrderId("123"), items: [], status: .pending)
        given(mockOrders).fetch(id: any()).willReturn(order)
        given(mockOrders).save(any()).willReturn(())

        let book = OrderBook(orders: mockOrders)

        // When
        try await book.updateStatus(OrderId("123"), to: .processing)
        let updated = try await book.getOrder(OrderId("123"))

        // Then - verify state changed
        #expect(updated.status == .processing)
    }
}
```

## Test Organization

```
Tests/AppTests/                     # mirrors Sources/ folder for folder
├── Core/
│   └── MoneyTests.swift                # Value object behavior
└── Orders/
    ├── OrderTests.swift                # Public face: model behavior
    ├── OrderStatusTests.swift          # Enum behavior
    ├── OrderBookTests.swift         # Actor behavior
    └── Internal/
        ├── APIOrderRepositoryTests.swift  # Adapter behavior via MockHTTP
        ├── OrderParsingTests.swift        # Parsing logic
        └── System/
            └── URLSessionHTTPTests.swift  # Integration only (real call, time-limited)
```

A test lives at the same path as the source it covers. `Internal/System/` is
the only folder coverage leaves out; everything else is unit-tested.

## Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter OrderTests

# Run specific test
swift test --filter "OrderTests/order computes total from items"
```

## Chicago School Summary

### What to Test

| Test Type           | What to Assert                                    |
|---------------------|---------------------------------------------------|
| Domain models       | Computed properties, state after mutations        |
| Actors/collections | Return values, thrown errors, resulting state     |
| Actors              | State after operations complete                   |

### What NOT to Test

- That a method was called N times
- The order of internal method calls
- Implementation details that don't affect observable state

### Red-Green-Refactor Cycle

```
1. RED    - Write a failing test that asserts expected STATE
2. GREEN  - Write minimal code to make the test pass
3. REFACTOR - Improve code while keeping tests green
```

Design emerges from this cycle - don't design upfront, let tests guide you.
