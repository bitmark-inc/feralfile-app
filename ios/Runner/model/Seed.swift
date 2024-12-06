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
        
        guard case .map(let map) = cbor else {
            throw LibAukError.other(reason: "ur:crypto-seed: CBOR doesn't contain a map.")
        }
        
        // Loop through the map to find the first bytes data
        var seedData: Data?
        for (_, value) in map {
            if case .bytes(let data) = value {
                seedData = data
                break
            }
        }
        
        // Verify we found valid seed data
        guard let finalSeedData = seedData else {
            throw LibAukError.other(reason: "ur:crypto-seed: Missing or invalid seed data.")
        }
        
        self.init(data: finalSeedData, name: "")
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
