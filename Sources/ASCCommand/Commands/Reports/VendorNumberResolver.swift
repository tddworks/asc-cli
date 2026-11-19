import ArgumentParser
import ASCKit

enum VendorNumberResolver {
    static func resolve(explicit: String?, storage: any AuthStorage) throws -> String {
        if let explicit {
            return explicit
        }
        let accounts = try storage.loadAll()
        if let active = accounts.first(where: \.isActive), let vendorNumber = active.vendorNumber {
            return vendorNumber
        }
        throw ValidationError(
            "No vendor number provided. Use --vendor-number or save it with: asc auth update --vendor-number <number>"
        )
    }
}
