
//
//  Atomic.swift
//
//
//  Created by supertext on 2023/3/22.
//

import Foundation

/// A thread-safe wrapper around a value.
@dynamicMemberLookup
@propertyWrapper
public final class Atomic<T> {
    private let lock: os_unfair_lock_t
    private var value: T
    public var projectedValue: Atomic<T> { self }
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }
    public init(wrappedValue: T) {
        self.value = wrappedValue
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }
    public var wrappedValue: T {
        get { around { value } }
        set { around { value = newValue } }
    }
    /// Access any suvalue of T
    public func read<U>(_ closure: (T) throws -> U) rethrows -> U {
        try around { try closure(self.value) }
    }
    /// Modify Any suvalue of T
    @discardableResult
    public func write<U>(_ closure: (inout T) throws -> U) rethrows -> U {
        try around { try closure(&self.value) }
    }
    /// Access  the protected Dictionary or Array.
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { around { self.value[keyPath: keyPath] } }
        set { around { self.value[keyPath: keyPath] = newValue } }
    }
    private func around<T>(_ closure: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try closure()
    }
}
