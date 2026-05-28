import XCTest
@testable import LocalMindLicense

final class LicenseValidatorTests: XCTestCase {
    func testEntitlementEnumCoversExpectedCases() {
        XCTAssertTrue(Entitlement.allCases.contains(.appleNotes))
        XCTAssertTrue(Entitlement.allCases.contains(.cloudBYOK))
        XCTAssertTrue(Entitlement.allCases.contains(.icloudSync))
    }
}
