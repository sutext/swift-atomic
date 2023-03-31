
//
//  Atomic.swift
//
//
//  Created by supertext on 2023/3/22.
//

import Foundation

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
/// AtomLock An `os_unfair_lock` wrapper.
public class AtomLock{
    private let unfair: os_unfair_lock_t
    deinit {
        unfair.deinitialize(count: 1)
        unfair.deallocate()
    }
    public init() {
        unfair = .allocate(capacity: 1)
        unfair.initialize(to: os_unfair_lock())
    }
    /// lock
    public func lock(){
        os_unfair_lock_lock(unfair)
    }
    /// unlock
    /// - Important: If `unlock` before `lock`
    public func unlock(){
        os_unfair_lock_unlock(unfair)
    }
}
#endif

#if os(Linux) || os(Windows)
public typealias AtomLock = NSLock
#endif


/// A thread-safe wrapper around a value.
@dynamicMemberLookup
@propertyWrapper
public class Atomic<T> {
    private var value: T
    private let lock: AtomLock = AtomLock()
    public var projectedValue: Atomic<T> { self }
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
    public var wrappedValue: T {
        get { around { value } }
        set { around { value = newValue } }
    }
    /// around some safer codes
    public func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try closure()
    }
    /// Access any suvalue of T
    public func read<U>(_ closure: (T) throws -> U) rethrows -> U {
        try around { try closure(self.value) }
    }
    /// Modify Any suvalue of T
    public func write<U>(_ closure: (inout T) throws -> U) rethrows -> U {
        try around { try closure(&self.value) }
    }
    /// Access  the protected Dictionary or Array.
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { around { self.value[keyPath: keyPath] } }
        set { around { self.value[keyPath: keyPath] = newValue } }
    }
    /// Access  the protected Dictionary or Array.
    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        get { around { self.value[keyPath: keyPath] } }
    }
}
