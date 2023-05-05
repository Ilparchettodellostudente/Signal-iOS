//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import GRDB
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Record

public struct SignalAccountRecord: SDSRecord {
    public weak var delegate: SDSRecordDelegate?

    public var tableMetadata: SDSTableMetadata {
        SignalAccountSerializer.table
    }

    public static var databaseTableName: String {
        SignalAccountSerializer.table.tableName
    }

    public var id: Int64?

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    public let recordType: SDSRecordType
    public let uniqueId: String

    // Properties
    public let contact: Data?
    public let contactAvatarHash: Data?
    public let contactAvatarJpegData: Data?
    public let multipleAccountLabelText: String
    public let recipientPhoneNumber: String?
    public let recipientUUID: String?

    public enum CodingKeys: String, CodingKey, ColumnExpression, CaseIterable {
        case id
        case recordType
        case uniqueId
        case contact
        case contactAvatarHash
        case contactAvatarJpegData
        case multipleAccountLabelText
        case recipientPhoneNumber
        case recipientUUID
    }

    public static func columnName(_ column: SignalAccountRecord.CodingKeys, fullyQualified: Bool = false) -> String {
        fullyQualified ? "\(databaseTableName).\(column.rawValue)" : column.rawValue
    }

    public func didInsert(with rowID: Int64, for column: String?) {
        guard let delegate = delegate else {
            owsFailDebug("Missing delegate.")
            return
        }
        delegate.updateRowId(rowID)
    }
}

// MARK: - Row Initializer

public extension SignalAccountRecord {
    static var databaseSelection: [SQLSelectable] {
        CodingKeys.allCases
    }

    init(row: Row) {
        id = row[0]
        recordType = row[1]
        uniqueId = row[2]
        contact = row[3]
        contactAvatarHash = row[4]
        contactAvatarJpegData = row[5]
        multipleAccountLabelText = row[6]
        recipientPhoneNumber = row[7]
        recipientUUID = row[8]
    }
}

// MARK: - StringInterpolation

public extension String.StringInterpolation {
    mutating func appendInterpolation(signalAccountColumn column: SignalAccountRecord.CodingKeys) {
        appendLiteral(SignalAccountRecord.columnName(column))
    }
    mutating func appendInterpolation(signalAccountColumnFullyQualified column: SignalAccountRecord.CodingKeys) {
        appendLiteral(SignalAccountRecord.columnName(column, fullyQualified: true))
    }
}

// MARK: - Deserialization

extension SignalAccount {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func fromRecord(_ record: SignalAccountRecord) throws -> SignalAccount {

        guard let recordId = record.id else {
            throw SDSError.invalidValue
        }

        switch record.recordType {
        case .signalAccount:

            let uniqueId: String = record.uniqueId
            let contactSerialized: Data? = record.contact
            let contact: Contact? = try SDSDeserialization.optionalUnarchive(contactSerialized, name: "contact")
            let contactAvatarHash: Data? = SDSDeserialization.optionalData(record.contactAvatarHash, name: "contactAvatarHash")
            let contactAvatarJpegDataObsolete: Data? = SDSDeserialization.optionalData(record.contactAvatarJpegData, name: "contactAvatarJpegDataObsolete")
            let multipleAccountLabelText: String = record.multipleAccountLabelText
            let recipientPhoneNumber: String? = record.recipientPhoneNumber
            let recipientUUID: String? = record.recipientUUID

            return SignalAccount(grdbId: recordId,
                                 uniqueId: uniqueId,
                                 contact: contact,
                                 contactAvatarHash: contactAvatarHash,
                                 contactAvatarJpegDataObsolete: contactAvatarJpegDataObsolete,
                                 multipleAccountLabelText: multipleAccountLabelText,
                                 recipientPhoneNumber: recipientPhoneNumber,
                                 recipientUUID: recipientUUID)

        default:
            owsFailDebug("Unexpected record type: \(record.recordType)")
            throw SDSError.invalidValue
        }
    }
}

// MARK: - SDSModel

extension SignalAccount: SDSModel {
    public var serializer: SDSSerializer {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        switch self {
        default:
            return SignalAccountSerializer(model: self)
        }
    }

    public func asRecord() throws -> SDSRecord {
        try serializer.asRecord()
    }

    public var sdsTableName: String {
        SignalAccountRecord.databaseTableName
    }

    public static var table: SDSTableMetadata {
        SignalAccountSerializer.table
    }

    public class func anyEnumerateIndexable(
        transaction: SDSAnyReadTransaction,
        block: (SDSIndexableModel) -> Void
    ) {
        anyEnumerate(transaction: transaction, batched: false) { model, _ in
            block(model)
        }
    }
}

// MARK: - DeepCopyable

extension SignalAccount: DeepCopyable {

    public func deepCopy() throws -> AnyObject {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        guard let id = self.grdbId?.int64Value else {
            throw OWSAssertionError("Model missing grdbId.")
        }

        do {
            let modelToCopy = self
            assert(type(of: modelToCopy) == SignalAccount.self)
            let uniqueId: String = modelToCopy.uniqueId
            // NOTE: If this generates build errors, you made need to
            // modify DeepCopy.swift to support this type.
            //
            // That might mean:
            //
            // * Implement DeepCopyable for this type (e.g. a model).
            // * Modify DeepCopies.deepCopy() to support this type (e.g. a collection).
            let contact: Contact?
            if let contactForCopy = modelToCopy.contact {
               contact = try DeepCopies.deepCopy(contactForCopy)
            } else {
               contact = nil
            }
            let contactAvatarHash: Data? = modelToCopy.contactAvatarHash
            let contactAvatarJpegDataObsolete: Data? = modelToCopy.contactAvatarJpegDataObsolete
            let multipleAccountLabelText: String = modelToCopy.multipleAccountLabelText
            let recipientPhoneNumber: String? = modelToCopy.recipientPhoneNumber
            let recipientUUID: String? = modelToCopy.recipientUUID

            return SignalAccount(grdbId: id,
                                 uniqueId: uniqueId,
                                 contact: contact,
                                 contactAvatarHash: contactAvatarHash,
                                 contactAvatarJpegDataObsolete: contactAvatarJpegDataObsolete,
                                 multipleAccountLabelText: multipleAccountLabelText,
                                 recipientPhoneNumber: recipientPhoneNumber,
                                 recipientUUID: recipientUUID)
        }

    }
}

// MARK: - Table Metadata

extension SignalAccountSerializer {

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    static var idColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "id", columnType: .primaryKey) }
    static var recordTypeColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "recordType", columnType: .int64) }
    static var uniqueIdColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "uniqueId", columnType: .unicodeString, isUnique: true) }
    // Properties
    static var contactColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "contact", columnType: .blob, isOptional: true) }
    static var contactAvatarHashColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "contactAvatarHash", columnType: .blob, isOptional: true) }
    static var contactAvatarJpegDataObsoleteColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "contactAvatarJpegDataObsolete", columnType: .blob, isOptional: true) }
    static var multipleAccountLabelTextColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "multipleAccountLabelText", columnType: .unicodeString) }
    static var recipientPhoneNumberColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "recipientPhoneNumber", columnType: .unicodeString, isOptional: true) }
    static var recipientUUIDColumn: SDSColumnMetadata { SDSColumnMetadata(columnName: "recipientUUID", columnType: .unicodeString, isOptional: true) }

    public static var table: SDSTableMetadata {
        SDSTableMetadata(collection: SignalAccount.collection(),
                         tableName: "model_SignalAccount",
                         columns: [
        idColumn,
        recordTypeColumn,
        uniqueIdColumn,
        contactColumn,
        contactAvatarHashColumn,
        contactAvatarJpegDataObsoleteColumn,
        multipleAccountLabelTextColumn,
        recipientPhoneNumberColumn,
        recipientUUIDColumn
        ])
    }
}

// MARK: - Save/Remove/Update

@objc
public extension SignalAccount {
    func anyInsert(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .insert, transaction: transaction)
    }

    // Avoid this method whenever feasible.
    //
    // If the record has previously been saved, this method does an overwriting
    // update of the corresponding row, otherwise if it's a new record, this
    // method inserts a new row.
    //
    // For performance, when possible, you should explicitly specify whether
    // you are inserting or updating rather than calling this method.
    func anyUpsert(transaction: SDSAnyWriteTransaction) {
        let isInserting: Bool
        if SignalAccount.anyFetch(uniqueId: uniqueId, transaction: transaction) != nil {
            isInserting = false
        } else {
            isInserting = true
        }
        sdsSave(saveMode: isInserting ? .insert : .update, transaction: transaction)
    }

    // This method is used by "updateWith..." methods.
    //
    // This model may be updated from many threads. We don't want to save
    // our local copy (this instance) since it may be out of date.  We also
    // want to avoid re-saving a model that has been deleted.  Therefore, we
    // use "updateWith..." methods to:
    //
    // a) Update a property of this instance.
    // b) If a copy of this model exists in the database, load an up-to-date copy,
    //    and update and save that copy.
    // b) If a copy of this model _DOES NOT_ exist in the database, do _NOT_ save
    //    this local instance.
    //
    // After "updateWith...":
    //
    // a) Any copy of this model in the database will have been updated.
    // b) The local property on this instance will always have been updated.
    // c) Other properties on this instance may be out of date.
    //
    // All mutable properties of this class have been made read-only to
    // prevent accidentally modifying them directly.
    //
    // This isn't a perfect arrangement, but in practice this will prevent
    // data loss and will resolve all known issues.
    func anyUpdate(transaction: SDSAnyWriteTransaction, block: (SignalAccount) -> Void) {

        block(self)

        guard let dbCopy = type(of: self).anyFetch(uniqueId: uniqueId,
                                                   transaction: transaction) else {
            return
        }

        // Don't apply the block twice to the same instance.
        // It's at least unnecessary and actually wrong for some blocks.
        // e.g. `block: { $0 in $0.someField++ }`
        if dbCopy !== self {
            block(dbCopy)
        }

        dbCopy.sdsSave(saveMode: .update, transaction: transaction)
    }

    // This method is an alternative to `anyUpdate(transaction:block:)` methods.
    //
    // We should generally use `anyUpdate` to ensure we're not unintentionally
    // clobbering other columns in the database when another concurrent update
    // has occurred.
    //
    // There are cases when this doesn't make sense, e.g. when  we know we've
    // just loaded the model in the same transaction. In those cases it is
    // safe and faster to do a "overwriting" update
    func anyOverwritingUpdate(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .update, transaction: transaction)
    }

    func anyRemove(transaction: SDSAnyWriteTransaction) {
        sdsRemove(transaction: transaction)
    }

    func anyReload(transaction: SDSAnyReadTransaction) {
        anyReload(transaction: transaction, ignoreMissing: false)
    }

    func anyReload(transaction: SDSAnyReadTransaction, ignoreMissing: Bool) {
        guard let latestVersion = type(of: self).anyFetch(uniqueId: uniqueId, transaction: transaction) else {
            if !ignoreMissing {
                owsFailDebug("`latest` was unexpectedly nil")
            }
            return
        }

        setValuesForKeys(latestVersion.dictionaryValue)
    }
}

// MARK: - SignalAccountCursor

@objc
public class SignalAccountCursor: NSObject, SDSCursor {
    private let transaction: GRDBReadTransaction
    private let cursor: RecordCursor<SignalAccountRecord>?

    init(transaction: GRDBReadTransaction, cursor: RecordCursor<SignalAccountRecord>?) {
        self.transaction = transaction
        self.cursor = cursor
    }

    public func next() throws -> SignalAccount? {
        guard let cursor = cursor else {
            return nil
        }
        guard let record = try cursor.next() else {
            return nil
        }
        let value = try SignalAccount.fromRecord(record)
        Self.modelReadCaches.signalAccountReadCache.didReadSignalAccount(value, transaction: transaction.asAnyRead)
        return value
    }

    public func all() throws -> [SignalAccount] {
        var result = [SignalAccount]()
        while true {
            guard let model = try next() else {
                break
            }
            result.append(model)
        }
        return result
    }
}

// MARK: - Obj-C Fetch

@objc
public extension SignalAccount {
    class func grdbFetchCursor(transaction: GRDBReadTransaction) -> SignalAccountCursor {
        let database = transaction.database
        do {
            let cursor = try SignalAccountRecord.fetchCursor(database)
            return SignalAccountCursor(transaction: transaction, cursor: cursor)
        } catch {
            owsFailDebug("Read failed: \(error)")
            return SignalAccountCursor(transaction: transaction, cursor: nil)
        }
    }

    // Fetches a single model by "unique id".
    class func anyFetch(uniqueId: String,
                        transaction: SDSAnyReadTransaction) -> SignalAccount? {
        assert(!uniqueId.isEmpty)

        switch transaction.readTransaction {
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT * FROM \(SignalAccountRecord.databaseTableName) WHERE \(signalAccountColumn: .uniqueId) = ?"
            return grdbFetchOne(sql: sql, arguments: [uniqueId], transaction: grdbTransaction)
        }
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    class func anyEnumerate(
        transaction: SDSAnyReadTransaction,
        block: (SignalAccount, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        anyEnumerate(transaction: transaction, batched: false, block: block)
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    class func anyEnumerate(
        transaction: SDSAnyReadTransaction,
        batched: Bool = false,
        block: (SignalAccount, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        let batchSize = batched ? Batching.kDefaultBatchSize : 0
        anyEnumerate(transaction: transaction, batchSize: batchSize, block: block)
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    //
    // If batchSize > 0, the enumeration is performed in autoreleased batches.
    class func anyEnumerate(
        transaction: SDSAnyReadTransaction,
        batchSize: UInt,
        block: (SignalAccount, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        switch transaction.readTransaction {
        case .grdbRead(let grdbTransaction):
            let cursor = SignalAccount.grdbFetchCursor(transaction: grdbTransaction)
            Batching.loop(batchSize: batchSize,
                          loopBlock: { stop in
                                do {
                                    guard let value = try cursor.next() else {
                                        stop.pointee = true
                                        return
                                    }
                                    block(value, stop)
                                } catch let error {
                                    owsFailDebug("Couldn't fetch model: \(error)")
                                }
                              })
        }
    }

    // Traverses all records' unique ids.
    // Records are not visited in any particular order.
    class func anyEnumerateUniqueIds(
        transaction: SDSAnyReadTransaction,
        block: (String, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        anyEnumerateUniqueIds(transaction: transaction, batched: false, block: block)
    }

    // Traverses all records' unique ids.
    // Records are not visited in any particular order.
    class func anyEnumerateUniqueIds(
        transaction: SDSAnyReadTransaction,
        batched: Bool = false,
        block: (String, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        let batchSize = batched ? Batching.kDefaultBatchSize : 0
        anyEnumerateUniqueIds(transaction: transaction, batchSize: batchSize, block: block)
    }

    // Traverses all records' unique ids.
    // Records are not visited in any particular order.
    //
    // If batchSize > 0, the enumeration is performed in autoreleased batches.
    class func anyEnumerateUniqueIds(
        transaction: SDSAnyReadTransaction,
        batchSize: UInt,
        block: (String, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        switch transaction.readTransaction {
        case .grdbRead(let grdbTransaction):
            grdbEnumerateUniqueIds(transaction: grdbTransaction,
                                   sql: """
                    SELECT \(signalAccountColumn: .uniqueId)
                    FROM \(SignalAccountRecord.databaseTableName)
                """,
                batchSize: batchSize,
                block: block)
        }
    }

    // Does not order the results.
    class func anyFetchAll(transaction: SDSAnyReadTransaction) -> [SignalAccount] {
        var result = [SignalAccount]()
        anyEnumerate(transaction: transaction) { (model, _) in
            result.append(model)
        }
        return result
    }

    // Does not order the results.
    class func anyAllUniqueIds(transaction: SDSAnyReadTransaction) -> [String] {
        var result = [String]()
        anyEnumerateUniqueIds(transaction: transaction) { (uniqueId, _) in
            result.append(uniqueId)
        }
        return result
    }

    class func anyCount(transaction: SDSAnyReadTransaction) -> UInt {
        switch transaction.readTransaction {
        case .grdbRead(let grdbTransaction):
            return SignalAccountRecord.ows_fetchCount(grdbTransaction.database)
        }
    }

    class func anyRemoveAllWithInstantation(transaction: SDSAnyWriteTransaction) {
        // To avoid mutationDuringEnumerationException, we need to remove the
        // instances outside the enumeration.
        let uniqueIds = anyAllUniqueIds(transaction: transaction)

        for uniqueId in uniqueIds {
            autoreleasepool {
                guard let instance = anyFetch(uniqueId: uniqueId, transaction: transaction) else {
                    owsFailDebug("Missing instance.")
                    return
                }
                instance.anyRemove(transaction: transaction)
            }
        }

        if ftsIndexMode != .never {
            FullTextSearchFinder.allModelsWereRemoved(collection: collection(), transaction: transaction)
        }
    }

    class func anyExists(
        uniqueId: String,
        transaction: SDSAnyReadTransaction
    ) -> Bool {
        assert(!uniqueId.isEmpty)

        switch transaction.readTransaction {
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT EXISTS ( SELECT 1 FROM \(SignalAccountRecord.databaseTableName) WHERE \(signalAccountColumn: .uniqueId) = ? )"
            let arguments: StatementArguments = [uniqueId]
            return try! Bool.fetchOne(grdbTransaction.database, sql: sql, arguments: arguments) ?? false
        }
    }
}

// MARK: - Swift Fetch

public extension SignalAccount {
    class func grdbFetchCursor(sql: String,
                               arguments: StatementArguments = StatementArguments(),
                               transaction: GRDBReadTransaction) -> SignalAccountCursor {
        do {
            let sqlRequest = SQLRequest<Void>(sql: sql, arguments: arguments, cached: true)
            let cursor = try SignalAccountRecord.fetchCursor(transaction.database, sqlRequest)
            return SignalAccountCursor(transaction: transaction, cursor: cursor)
        } catch {
            Logger.verbose("sql: \(sql)")
            owsFailDebug("Read failed: \(error)")
            return SignalAccountCursor(transaction: transaction, cursor: nil)
        }
    }

    class func grdbFetchOne(sql: String,
                            arguments: StatementArguments = StatementArguments(),
                            transaction: GRDBReadTransaction) -> SignalAccount? {
        assert(!sql.isEmpty)

        do {
            let sqlRequest = SQLRequest<Void>(sql: sql, arguments: arguments, cached: true)
            guard let record = try SignalAccountRecord.fetchOne(transaction.database, sqlRequest) else {
                return nil
            }

            let value = try SignalAccount.fromRecord(record)
            Self.modelReadCaches.signalAccountReadCache.didReadSignalAccount(value, transaction: transaction.asAnyRead)
            return value
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class SignalAccountSerializer: SDSSerializer {

    private let model: SignalAccount
    public required init(model: SignalAccount) {
        self.model = model
    }

    // MARK: - Record

    func asRecord() throws -> SDSRecord {
        let id: Int64? = model.grdbId?.int64Value

        let recordType: SDSRecordType = .signalAccount
        let uniqueId: String = model.uniqueId

        // Properties
        let contact: Data? = optionalArchive(model.contact)
        let contactAvatarHash: Data? = model.contactAvatarHash
        let contactAvatarJpegData: Data? = model.contactAvatarJpegDataObsolete
        let multipleAccountLabelText: String = model.multipleAccountLabelText
        let recipientPhoneNumber: String? = model.recipientPhoneNumber
        let recipientUUID: String? = model.recipientUUID

        return SignalAccountRecord(delegate: model, id: id, recordType: recordType, uniqueId: uniqueId, contact: contact, contactAvatarHash: contactAvatarHash, contactAvatarJpegData: contactAvatarJpegData, multipleAccountLabelText: multipleAccountLabelText, recipientPhoneNumber: recipientPhoneNumber, recipientUUID: recipientUUID)
    }
}

// MARK: - Deep Copy

#if TESTABLE_BUILD
@objc
public extension SignalAccount {
    // We're not using this method at the moment,
    // but we might use it for validation of
    // other deep copy methods.
    func deepCopyUsingRecord() throws -> SignalAccount {
        guard let record = try asRecord() as? SignalAccountRecord else {
            throw OWSAssertionError("Could not convert to record.")
        }
        return try SignalAccount.fromRecord(record)
    }
}
#endif
