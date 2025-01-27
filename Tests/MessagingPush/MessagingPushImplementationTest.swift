@testable import CioMessagingPush
@testable import CioTracking
@testable import Common
import Foundation
import SharedTests
import XCTest

class MessagingPushImplementationTest: UnitTest {
    private var mockCustomerIO = CustomerIOInstanceMock()
    private var messagingPush: MessagingPushImplementation!

    private let profileStoreMock = ProfileStoreMock()
    private let queueMock = QueueMock()
    private let globalDataStoreMock = GlobalDataStoreMock()
    private let sdkConfigStoreMock = SdkConfigStoreMock()
    private let deviceAttributesMock = DeviceAttributesProviderMock()
    private let deviceInfoMock = DeviceInfoMock()

    override func setUp() {
        super.setUp()

        mockCustomerIO.siteId = testSiteId
        messagingPush = MessagingPushImplementation(siteId: testSiteId, profileStore: profileStoreMock,
                                                    backgroundQueue: queueMock,
                                                    globalDataStore: globalDataStoreMock, logger: log,
                                                    sdkConfigStore: sdkConfigStoreMock, jsonAdapter: jsonAdapter,
                                                    deviceAttributesProvider: deviceAttributesMock,
                                                    dateUtil: dateUtilStub,
                                                    deviceInfo: deviceInfoMock)
    }

    // MARK: registerDeviceToken

    func test_registerDeviceToken_givenNoCustomerIdentified_expectNoAddingToQueue_expectStoreDeviceToken() {
        let givenDeviceToken = String.random
        profileStoreMock.identifier = nil

        messagingPush.registerDeviceToken(givenDeviceToken)

        XCTAssertFalse(queueMock.mockCalled)
        XCTAssertEqual(globalDataStoreMock.pushDeviceToken, givenDeviceToken)
    }

    func test_registerDeviceToken_givenCustomerIdentified_expectAddTaskToQueue_expectStoreDeviceToken() {
        let givenDeviceToken = String.random
        let givenIdentifier = String.random
        let givenDefaultAttributes = ["foo": "bar"]
        profileStoreMock.identifier = givenIdentifier
        deviceInfoMock.underlyingOsName = "iOS"
        queueMock.addTaskReturnValue = (success: true, queueStatus: QueueStatus.successAddingSingleTask)
        deviceAttributesMock.getDefaultDeviceAttributesClosure = { onComplete in
            onComplete(givenDefaultAttributes)
        }

        messagingPush.registerDeviceToken(givenDeviceToken)

        XCTAssertEqual(queueMock.addTaskCallsCount, 1)
        XCTAssertEqual(queueMock.addTaskReceivedArguments?.type, QueueTaskType.registerPushToken.rawValue)
        let actualQueueTaskData = queueMock.addTaskReceivedArguments!.data
            .value as? RegisterPushNotificationQueueTaskData

        XCTAssertNotNil(actualQueueTaskData)
        XCTAssertEqual(actualQueueTaskData?.profileIdentifier, givenIdentifier)
        let expectedJsonString = jsonAdapter.toJsonString(RegisterDeviceRequest(device:
            Device(token: givenDeviceToken,
                   platform: "iOS",
                   lastUsed: dateUtilStub
                       .givenNow,
                   attributes: StringAnyEncodable(givenDefaultAttributes))))
        XCTAssertEqual(actualQueueTaskData?.attributesJsonString, expectedJsonString)

        XCTAssertEqual(globalDataStoreMock.pushDeviceToken, givenDeviceToken)
    }

    func test_registerDeviceToken_givenNoOsNameAvailable_expectNoAddingToQueue() {
        let givenDeviceToken = String.random
        deviceInfoMock.underlyingOsName = nil
        profileStoreMock.identifier = String.random

        messagingPush.registerDeviceToken(givenDeviceToken)

        XCTAssertFalse(queueMock.mockCalled)
        XCTAssertEqual(globalDataStoreMock.pushDeviceToken, givenDeviceToken)
    }

    // MARK: deleteDeviceToken

    func test_deleteDeviceToken_givenNoCustomerIdentified_givenNoExistingPushToken_expectNoAddingTaskToQueue() {
        globalDataStoreMock.pushDeviceToken = nil
        profileStoreMock.identifier = nil

        messagingPush.deleteDeviceToken()

        XCTAssertFalse(queueMock.mockCalled)
        XCTAssertNil(globalDataStoreMock.pushDeviceToken)
    }

    func test_deleteDeviceToken_givenCustomerIdentified_givenNoExistingPushToken_expectNoAddingTaskToQueue() {
        globalDataStoreMock.pushDeviceToken = nil
        profileStoreMock.identifier = String.random

        messagingPush.deleteDeviceToken()

        XCTAssertFalse(queueMock.mockCalled)
        XCTAssertNil(globalDataStoreMock.pushDeviceToken)
    }

    func test_deleteDeviceToken_givenNoCustomerIdentified_givenExistingPushToken_expectNoAddingTaskToQueue() {
        globalDataStoreMock.pushDeviceToken = String.random
        profileStoreMock.identifier = nil

        messagingPush.deleteDeviceToken()

        XCTAssertFalse(queueMock.mockCalled)
        XCTAssertNotNil(globalDataStoreMock.pushDeviceToken)
    }

    func test_deleteDeviceToken_givenCustomerIdentified_givenExistingPushToken_expectAddTaskToQueue() {
        let givenDeviceToken = String.random
        let givenIdentifier = String.random

        globalDataStoreMock.pushDeviceToken = givenDeviceToken
        profileStoreMock.identifier = givenIdentifier
        queueMock.addTaskReturnValue = (success: true, queueStatus: QueueStatus.successAddingSingleTask)

        messagingPush.deleteDeviceToken()

        XCTAssertEqual(queueMock.addTaskCallsCount, 1)
        XCTAssertEqual(queueMock.addTaskReceivedArguments?.type, QueueTaskType.deletePushToken.rawValue)
        let actualQueueTaskData = queueMock.addTaskReceivedArguments!.data.value as? DeletePushNotificationQueueTaskData

        XCTAssertNotNil(actualQueueTaskData)
        XCTAssertEqual(actualQueueTaskData?.profileIdentifier, givenIdentifier)
        XCTAssertEqual(actualQueueTaskData?.deviceToken, givenDeviceToken)

        XCTAssertNotNil(globalDataStoreMock.pushDeviceToken)
    }

    // MARK: trackMetric

    func test_trackMetric_expectAddTaskToQueue() {
        let givenDeliveryId = String.random
        let givenEvent = Metric.delivered
        let givenDeviceToken = String.random
        queueMock.addTaskReturnValue = (success: true, queueStatus: QueueStatus.successAddingSingleTask)

        messagingPush.trackMetric(deliveryID: givenDeliveryId, event: givenEvent, deviceToken: givenDeviceToken)

        XCTAssertEqual(queueMock.addTaskCallsCount, 1)
        XCTAssertEqual(queueMock.addTaskReceivedArguments?.type, QueueTaskType.trackPushMetric.rawValue)
        let actualQueueTaskData = queueMock.addTaskReceivedArguments!.data.value as? MetricRequest

        XCTAssertNotNil(actualQueueTaskData)
        XCTAssertEqual(actualQueueTaskData?.deliveryId, givenDeliveryId)
        XCTAssertEqual(actualQueueTaskData?.event, givenEvent)
        XCTAssertEqual(actualQueueTaskData?.deviceToken, givenDeviceToken)
    }
}
