//
//  NW.Protocol.swift
//  Core
//
//  Created by Ivan Kh on 21.12.2022.
//

import Foundation
import Network


// Create a class that implements a framing protocol.
extension Network.NW {
    class BlackProtocol: NWProtocolFramerImplementation {

        // Create a global definition of your game protocol to add to connections.
        static let definition = NWProtocolFramer.Definition(implementation: BlackProtocol.self)

        // Set a name for your protocol for use in debugging.
        static var label: String { return "BlackMedia" }

        // Set the default behavior for most framing protocol functions.
        required init(framer: NWProtocolFramer.Instance) { }
        func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
        func wakeup(framer: NWProtocolFramer.Instance) { }
        func stop(framer: NWProtocolFramer.Instance) -> Bool { return true }
        func cleanup(framer: NWProtocolFramer.Instance) { }

        // Whenever the application sends a message, add your protocol header and forward the bytes.
        func handleOutput(framer: NWProtocolFramer.Instance,
                          message: NWProtocolFramer.Message,
                          messageLength: Int,
                          isComplete: Bool) {
            
            // Extract the type of message.
            guard let type = MessageType(message) else { assertionFailure(); return }

            // Create a header using the type and length.
            let header = Header(type: type.rawValue, length: UInt32(messageLength))

            // Write the header.
            framer.writeOutput(data: header.encodedData)

            // Ask the connection to insert the content of the app message after your header.
            do {
                try framer.writeOutputNoCopy(length: messageLength)
            }
            catch let error {
                print("Hit error writing \(error)")
            }
        }

        // Whenever new bytes are available to read, try to parse out your message format.
        func handleInput(framer: NWProtocolFramer.Instance) -> Int {
            while true {
                // Try to read out a single header.
                var tempHeader: Header? = nil
                let headerSize = Header.encodedSize
                let parsed = framer.parseInput(minimumIncompleteLength: headerSize,
                                               maximumLength: headerSize) { (buffer, isComplete) -> Int in
                    guard let buffer = buffer else {
                        return 0
                    }
                    if buffer.count < headerSize {
                        return 0
                    }
                    tempHeader = Header(buffer)
                    return headerSize
                }

                // If you can't parse out a complete header, stop parsing and return headerSize,
                // which asks for that many more bytes.
                guard parsed, let header = tempHeader else {
                    return headerSize
                }

                // Create an object to deliver the message.
                guard let messageType = MessageType(rawValue: header.type) else {
                    assertionFailure()
                    return headerSize
                }
                
                let message = NWProtocolFramer.Message(messageType)

                // Deliver the body of the message, along with the message object.
                if !framer.deliverInputNoCopy(length: Int(header.length), message: message, isComplete: true) {
                    return 0
                }
            }
        }
    }
}


// Define the types of commands for your game to use.
extension Network.NW.BlackProtocol {
    enum MessageType: UInt8 {
        case identity = 0
        case data = 1
        case pair = 2
        case skip = 3
    }
}


extension Network.Peer.Data {
    init?(type: Network.NW.BlackProtocol.MessageType?, data: Data) {
        guard let type else { return nil }

        switch type {
        case .data: self = .data(data)
        case .pair: self = .pair
        case .skip: self = .skip
        case .identity: return nil
        }
    }
}


// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
    convenience init(_ type: Network.NW.BlackProtocol.MessageType) {
        self.init(definition: Network.NW.BlackProtocol.definition)
        self["Black"] = type
    }
}


extension Network.NW.BlackProtocol.MessageType {
    init?(_ message: NWProtocolFramer.Message?) {
        guard let message else { return nil }
        guard let type = message["Black"] as? Network.NW.BlackProtocol.MessageType else { return nil }
        self = type
    }
}


// Define a protocol header structure to help encode and decode bytes.
extension Network.NW.BlackProtocol {
    struct Header: Codable {
        let type: UInt8
        let length: UInt32
        
        init(type: UInt8, length: UInt32) {
            self.type = type
            self.length = length
        }
        
        init(_ buffer: UnsafeMutableRawBufferPointer) {
            var tempType: UInt8 = 0
            var tempLength: UInt32 = 0
            
            withUnsafeMutableBytes(of: &tempType) { typePtr in
                typePtr.copyMemory(
                    from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
                                                 count: MemoryLayout<UInt8>.size))
            }
            
            withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
                lengthPtr.copyMemory(
                    from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt8>.size),
                                                 count: MemoryLayout<UInt32>.size))
            }
            
            type = tempType
            length = tempLength
        }
        
        var encodedData: Data {
            var tempType = type
            var tempLength = length
            var data = Data(bytes: &tempType, count: MemoryLayout<UInt8>.size)
            data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))
            return data
        }
        
        static var encodedSize: Int {
            return MemoryLayout<UInt8>.size + MemoryLayout<UInt32>.size
        }
    }
}


extension NWConnection.ContentContext {
    var blackMessage: NWProtocolFramer.Message? {
        protocolMetadata(definition: Network.NW.BlackProtocol.definition) as? NWProtocolFramer.Message
    }
}
