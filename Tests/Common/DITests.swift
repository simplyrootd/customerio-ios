@testable import Common
import Foundation
import SharedTests
import XCTest

class DiCommonTests: XCTestCase {
    func testDependencyGraphComplete() {
        let graph = DICommon.getInstance(siteId: "test")
        // We cannot resolve all dependencies until the creds store is resolved.
        var credsStore = graph.sdkCredentialsStore
        credsStore.credentials = SdkCredentials(apiKey: String.random, region: Region.EU)

        for dependency in DependencyCommon.allCases {
            XCTAssertNotNil(graph.inject(dependency),
                            "Dependency: \(dependency) not able to resolve in dependency graph. Maybe you're using the Sourcery template incorrectly or there is a circular dependency in your graph?")
        }
    }
}