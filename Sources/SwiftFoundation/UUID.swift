//
//  UUID.swift
//  SwiftFoundation
//
//  Created by Alsey Coleman Miller on 6/29/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
    import Foundation
#elseif os(Linux)
    import Glibc
    import CUUID
#endif

// MARK: - Linux

#if os(Linux) || XcodeLinux
    
    /// A representation of a universally unique identifier (```UUID```).
    public struct UUID: ByteValue, Equatable, Hashable, RawRepresentable, CustomStringConvertible {
        
        // MARK: - Static Properties
        
        public static let length = 16
        public static let stringLength = 36
        public static let unformattedStringLength = 32
        
        // MARK: - Properties
        
        public var bytes: uuid_t
        
        // MARK: - Initialization
        
        /// Create a new UUID with RFC 4122 version 4 random bytes
        public init() {
            
            var uuid = uuid_t(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
            
            withUnsafeMutablePointer(&uuid, { (valuePointer: UnsafeMutablePointer<uuid_t>) in
                
                uuid_generate(unsafeBitCast(valuePointer, to: UnsafeMutablePointer<UInt8>.self))
            })
            
            self.bytes = uuid
        }
        
        /// Initializes a UUID with the specified bytes.
        public init(bytes: uuid_t) {
            
            self.bytes = bytes
        }
    }
    
    // MARK: - RawRepresentable
    
    public extension UUID {
        
        init?(rawValue: String) {
            
            let uuidPointer = UnsafeMutablePointer<uuid_t>(allocatingCapacity: 1)
            
            defer { uuidPointer.deallocateCapacity(1) }
            
            guard uuid_parse(rawValue, unsafeBitCast(uuidPointer, to: UnsafeMutablePointer<UInt8>.self)) != -1
                else { return nil }
            
            self.bytes = uuidPointer.pointee
        }
        
        var rawValue: String {
            
            var uuidCopy = bytes
            
            var uuidString = POSIXUUIDStringType(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            
            withUnsafeMutablePointers(&uuidCopy, &uuidString) { (uuidPointer: UnsafeMutablePointer<uuid_t>, uuidStringPointer: UnsafeMutablePointer<POSIXUUIDStringType>) -> Void in
                
                let stringBuffer = unsafeBitCast(uuidStringPointer, to: UnsafeMutablePointer<Int8>.self)
                
                let uuidBuffer = unsafeBitCast(uuidPointer, to: UnsafeMutablePointer<UInt8>.self)
                
                uuid_unparse(unsafeBitCast(uuidBuffer, to: UnsafePointer<UInt8>.self), stringBuffer)
            }
            
            return withUnsafeMutablePointer(&uuidString, { (valuePointer: UnsafeMutablePointer<POSIXUUIDStringType>) -> String in
                
                let buffer = unsafeBitCast(valuePointer, to: UnsafeMutablePointer<CChar>.self)
                
                return String(validatingUTF8: unsafeBitCast(buffer, to: UnsafePointer<CChar>.self))!
            })
        }
    }
    
    // MARK: - Hashable
    
    public extension UUID {
        
        var hashValue: Int {
            
            return toData().hashValue
        }
    }

#endif

// MARK: - Darwin

#if (os(OSX) || os(iOS) || os(watchOS) || os(tvOS)) && !XcodeLinux
    
    public typealias UUID = Foundation.UUID
    
    extension Foundation.UUID: ByteValue {
        
        public init(bytes: uuid_t) {
            
            self.init(uuid: bytes)
        }
        
        public var bytes: uuid_t {
            
            get { return uuid }
            
            set { self = Foundation.UUID(uuid: newValue) }
        }
    }
    
#endif

// MARK: - DataConvertible

extension UUID: DataConvertible {
    
    public init?(data: Data) {
        
        guard data.count == UUID.length else { return nil }
        
        self.init(bytes: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]))
    }
    
    public func toData() -> Data {
        
        return Data(bytes: [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7, bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15])
    }
}

// MARK: - Private

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    private typealias POSIXUUIDStringType = uuid_string_t
#elseif os(Linux)
    private typealias POSIXUUIDStringType = (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)
#endif
