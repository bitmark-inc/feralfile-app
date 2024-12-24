//
//  Seed.swift
//  
//
//  Created by Ho Hien on 8/11/21.
//

import Foundation
import URKit

public class Seed: Codable {
    public let data: Data
    public let name: String
    public let creationDate: Date?
    public let passphrase: String?
    
    init(data: Data, name: String, creationDate: Date? = nil, passphrase: String? = "") {
        self.data = data
        self.name = name
        self.creationDate = creationDate
        self.passphrase = passphrase
    }
    
    convenience init(urString: String) throws {
        guard let ur = try? UR(urString: urString) else {
            throw LibAukError.other(reason: "ur:crypto-seed: Invalid UR data.")
        }
        
        guard let cbor = try? CBOR(ur.cbor) else {
            throw LibAukError.other(reason: "ur:crypto-seed: Invalid CBOR data.")
        }
        try self.init(cbor: cbor)

    }

    convenience init(cbor: CBOR) throws {
        guard case let CBOR.orderedMap(orderedMap) = cbor else {
            throw LibAukError.other(reason: "ur:crypto-seed: CBOR doesn't contain a map.")
        }

        let iterator = orderedMap.makeIterator()
        var seedData: Data?
        var creationDate: Date? = nil
        var name: String = ""
        var passphrase: String = ""

        while let element = iterator.next() {
            let (indexElement, valueElement) = element

            guard case let CBOR.unsignedInt(index) = indexElement else {
                throw LibAukError.other(reason: "ur:crypto-seed: CBOR contains invalid keys.")
            }

            switch index {
            case 1:
                guard case let CBOR.data(data) = valueElement else {
                    throw LibAukError.other(reason: "ur:crypto-seed: CBOR doesn't contain data field.")
                }
                seedData = data
            case 2:
                guard case let CBOR.date(d) = valueElement else {
                    throw LibAukError.other(reason: "ur:crypto-seed: CreationDate field doesn't contain a date.")
                }
                creationDate = d
            case 3:
                guard case let CBOR.utf8String(s) = valueElement else {
                    throw LibAukError.other(reason: "ur:crypto-seed: Name field doesn't contain a string.")
                }
                name = s
            case 4:
                guard case let CBOR.utf8String(s) = valueElement else {
                    throw LibAukError.other(reason: "ur:crypto-seed: Passphrase field doesn't contain a string.")
                }
                passphrase = s
            default:
                throw LibAukError.other(reason: "ur:crypto-seed: CBOR contains invalid keys.")
            }
        }
        
        
        self.init(data: seedData!, name: name, creationDate: creationDate, passphrase: passphrase)
    }
}

public enum LibAukError: Error {
    case initEncryptionError
    case keyCreationError
    case invalidMnemonicError
    case emptyKey
    case keyCreationExistingError(key: String)
    case keyDerivationError
    case other(reason: String)
}

extension LibAukError: LocalizedError {
    public var errorDescription: String? {
        errorMessage
    }

    public var failureReason: String? {
        errorMessage
    }

    public var recoverySuggestion: String? {
        errorMessage
    }

    var errorMessage: String {
        switch self {
        case .initEncryptionError:
            return "init encryption error"
        case .keyCreationError:
            return "create key error"
        case .invalidMnemonicError:
            return "invalid mnemonic error"
        case .emptyKey:
            return "empty Key"
        case .keyCreationExistingError:
            return "create key error: key exists"
        case .keyDerivationError:
            return "key derivation error"
        case .other(let reason):
            return reason
        }
    }
}
