import Testing
@testable import Domain

@Suite
struct PaginatedResponseTests {

    @Test
    func `has more is true when next cursor exists`() {
        let response = PaginatedResponse(data: [1, 2, 3], nextCursor: "abc")
        #expect(response.hasMore == true)
    }

    @Test
    func `has more is false when next cursor is nil`() {
        let response = PaginatedResponse(data: [1, 2, 3], nextCursor: nil)
        #expect(response.hasMore == false)
    }

    @Test
    func `empty response has no data`() {
        let response = PaginatedResponse<String>(data: [])
        #expect(response.data.isEmpty)
        #expect(response.hasMore == false)
        #expect(response.totalCount == nil)
    }

    @Test
    func `response preserves total count`() {
        let response = PaginatedResponse(data: ["a"], totalCount: 100)
        #expect(response.totalCount == 100)
    }
}
