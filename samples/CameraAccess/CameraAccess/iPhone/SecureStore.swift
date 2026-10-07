import Foundation
import Security

struct SecureStore {
  enum StoreError: Error {
    case unexpectedStatus(OSStatus)
    case invalidData
  }

  let service: String

  init(service: String = Bundle.main.bundleIdentifier ?? "com.weverton.visionclaw") {
    self.service = service
  }

  func value(for account: String) throws -> String? {
    var query = baseQuery(account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw StoreError.unexpectedStatus(status) }
    guard let data = result as? Data,
          let value = String(data: data, encoding: .utf8) else {
      throw StoreError.invalidData
    }
    return value
  }

  func set(_ value: String, for account: String) throws {
    guard let data = value.data(using: .utf8) else { throw StoreError.invalidData }
    let query = baseQuery(account: account)
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecItemNotFound {
      var item = query
      item.merge(attributes) { _, new in new }
      let addStatus = SecItemAdd(item as CFDictionary, nil)
      guard addStatus == errSecSuccess else { throw StoreError.unexpectedStatus(addStatus) }
    } else if updateStatus != errSecSuccess {
      throw StoreError.unexpectedStatus(updateStatus)
    }
  }

  func remove(_ account: String) throws {
    let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw StoreError.unexpectedStatus(status)
    }
  }

  private func baseQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}
