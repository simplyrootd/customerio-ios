import Foundation

/**
 Guarantee the wrapped value is only ever accessed from one thread at a time.

 Class is public because public fields may be Atomic.
 This class is only used for internal SDK development, only. It's not part of the official SDK.
 */
@propertyWrapper
public struct Atomic<DataType: Any> {
    fileprivate let lock = Lock.unsafeInit() // we want to have a new lock for every instance of Atomic.

    fileprivate var unsafeValue: DataType

    /// Safely accesses the unsafe value from within the context of its exclusive-access queue
    public var wrappedValue: DataType {
        get {
            lock.lock()
            defer { lock.unlock() }
            return unsafeValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            unsafeValue = newValue
        }
    }

    /**
     Initializer that satisfies @propertyWrapper's requirements.
     With this initializer created, you can assign default values to our wrapped properties,
     like this: `@Atomic var foo = Foo()`
     */
    public init(wrappedValue: DataType) {
        self.unsafeValue = wrappedValue
    }
}
