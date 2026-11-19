public struct PaginatedResponse<T: Sendable>: Sendable {
    public let data: [T]
    public let nextCursor: String?
    public let totalCount: Int?

    public init(data: [T], nextCursor: String? = nil, totalCount: Int? = nil) {
        self.data = data
        self.nextCursor = nextCursor
        self.totalCount = totalCount
    }

    public var hasMore: Bool {
        nextCursor != nil
    }
}
