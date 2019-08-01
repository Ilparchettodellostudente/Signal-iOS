//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc(OWSStorageServiceOperation)
class StorageServiceOperation: OWSOperation {
    // MARK: -

    @objc
    static func recordPendingDeletions(deletedIds: [AccountId]) {
        let operation = StorageServiceOperation(mode: .pendingDeletions(deletedIds))
        operationQueue.addOperation(operation)

        // Schedule a backup to run in the next 10 minutes
        // if one hasn't been scheduled already.
        scheduleBackupIfNecessary()
    }

    @objc
    static func recordPendingUpdate(updatedIds: [AccountId]) {
        let operation = StorageServiceOperation(mode: .pendingUpdates(updatedIds))
        operationQueue.addOperation(operation)

        // Schedule a backup to run in the next 10 minutes
        // if one hasn't been scheduled already.
        scheduleBackupIfNecessary()
    }

    @objc
    static func backupPendingChanges() {
        let operation = StorageServiceOperation(mode: .backup)
        operationQueue.addOperation(operation)
    }

    @objc
    static func restoreManifestIfNecessary() {
        let operation = StorageServiceOperation(mode: .restore)
        operationQueue.addOperation(operation)
    }

    // MARK: - Dependencies

    private var databaseStorage: SDSDatabaseStorage {
        return SDSDatabaseStorage.shared
    }

    static var keyValueStore: SDSKeyValueStore {
        return SDSKeyValueStore(collection: "kOWSStorageServiceOperation_IdentifierMap")
    }

    // MARK: -

    private static let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = logTag()
        return queue
    }()

    private enum Mode {
        case pendingUpdates([AccountId])
        case pendingDeletions([AccountId])
        case backup
        case restore
    }
    private let mode: Mode

    private init(mode: Mode) {
        self.mode = mode
        super.init()
        self.remainingRetries = 4
    }

    // MARK: - Backup Scheduling

    private static var scheduledBackupInterval: TimeInterval = kMinuteInterval * 10
    private static var backupTimer: Timer?

    // Schedule a one time backup. By default, this will happen ten
    // minutes after the first pending change is recorded.
    private static func scheduleBackupIfNecessary() {
        // If we already have a backup scheduled, do nothing
        DispatchQueue.main.async {
            guard backupTimer == nil else { return }

            backupTimer = Timer.scheduledTimer(
                timeInterval: scheduledBackupInterval,
                target: self,
                selector: #selector(backupTimerFired),
                userInfo: nil,
                repeats: false
            )
        }
    }

    @objc private static func backupTimerFired(_ timer: Timer) {
        backupTimer?.invalidate()
        backupTimer = nil

        backupPendingChanges()
    }

    // MARK: - Run

    // Called every retry, this is where the bulk of the operation's work should go.
    override public func run() {
        Logger.debug("")

        switch mode {
        case .pendingUpdates(let updatedIds):
            recordPendingUpdates(updatedIds)
        case .pendingDeletions(let deletedIds):
            recordPendingDeletions(deletedIds)
        case .backup:
            backupPendingChanges()
        case .restore:
            restoreManifestIfNecessary()
        }
    }

    // MARK: Mark Pending Changes

    private func recordPendingUpdates(_ updatedIds: [AccountId]) {
        databaseStorage.write { transaction in
            var pendingChanges = StorageServiceOperation.accountChangeMap(transaction: transaction)

            for accountId in updatedIds {
                pendingChanges[accountId] = .updated
            }

            StorageServiceOperation.setAccountChangeMap(pendingChanges, transaction: transaction)
        }

        reportSuccess()
    }

    private func recordPendingDeletions(_ deletedIds: [AccountId]) {
        databaseStorage.write { transaction in
            var pendingChanges = StorageServiceOperation.accountChangeMap(transaction: transaction)

            for accountId in deletedIds {
                pendingChanges[accountId] = .deleted
            }

            StorageServiceOperation.setAccountChangeMap(pendingChanges, transaction: transaction)
        }

        reportSuccess()
    }

    // MARK: Backup

    private func backupPendingChanges() {
        var pendingChanges: [AccountId: ChangeState] = [:]
        var identifierMap: BidirectionalDictionary<AccountId, StorageService.ContactIdentifier> = [:]
        var version: UInt64 = 0

        var updatedRecords: [StorageServiceProtoContactRecord] = []

        databaseStorage.read { transaction in
            pendingChanges = StorageServiceOperation.accountChangeMap(transaction: transaction)
            identifierMap = StorageServiceOperation.accountToIdentifierMap(transaction: transaction)
            version = StorageServiceOperation.manifestVersion(transaction: transaction) ?? 0

            // Build an up-to-date contact record for every pending update
            updatedRecords =
                pendingChanges.lazy.filter { $0.value == .updated }.compactMap { accountId, _ in
                    var hasBuildError = false

                    defer {
                        // Clear the pending change only if we were able to successfully build a record.
                        if !hasBuildError {
                            pendingChanges[accountId] = nil
                        }
                    }

                    do {
                        guard let contactIdentifier = identifierMap[accountId] else {
                            // This is a new contact, we need to generate an ID
                            let contactIdentifier = StorageService.ContactIdentifier.generate()
                            identifierMap[accountId] = contactIdentifier

                            return try StorageServiceProtoContactRecord.build(
                                for: accountId,
                                contactIdentifier: contactIdentifier,
                                transaction: transaction
                            )
                        }

                        return try StorageServiceProtoContactRecord.build(
                            for: accountId,
                            contactIdentifier: contactIdentifier,
                            transaction: transaction
                        )
                    } catch {
                        owsFailDebug("Unexpectedly failed to process changes for account \(error)")
                        hasBuildError = true

                        // If for some reason we failed, we'll just skip it and try this account again next backup.
                        return nil
                    }
            }
        }

        // Lookup the contact identifier for every pending deletion
        let deletedIdentifiers: [StorageService.ContactIdentifier] =
            pendingChanges.filter { $0.value == .deleted }.compactMap { accountId, _ in
                // Clear the pending change
                pendingChanges[accountId] = nil

                guard let contactIdentifier = identifierMap[accountId] else {
                    // This contact doesn't exist in our records, it may have been
                    // added and then deleted before a backup occured. We can safely skip it.
                    return nil
                }

                // Remove this contact from the mapping
                identifierMap[accountId] = nil

                return contactIdentifier
        }

        // Bump the manifest version
        version += 1

        let manifestBuilder = StorageServiceProtoManifestRecord.builder(version: version)
        manifestBuilder.setKeys(identifierMap.map { $1.data })

        let manifest: StorageServiceProtoManifestRecord
        do {
            manifest = try manifestBuilder.build()
        } catch {
            owsFailDebug("unexpectedly failed to build manifest \(error)")
            let retryableError = error as NSError
            retryableError.isRetryable = true
            return reportError(withUndefinedRetry: retryableError)
        }

        StorageService.updateManifest(
            manifest,
            newContacts: updatedRecords,
            deletedContacts: deletedIdentifiers
        ).done(on: .global()) { conflictingManifest in
            guard let conflictingManifest = conflictingManifest else {
                // Successfuly updated, store our changes.
                self.databaseStorage.write { transaction in
                    StorageServiceOperation.setAccountChangeMap(pendingChanges, transaction: transaction)
                    StorageServiceOperation.setManifestVersion(version, transaction: transaction)
                    StorageServiceOperation.setAccountToIdentifierMap(identifierMap, transaction: transaction)
                }

                return self.reportSuccess()
            }

            // Throw away all our work, resolve conflicts, and try again.
            self.mergeExistingManifestWithNewManifest(conflictingManifest, backupAfterSuccess: true)
        }.catch { error in
            self.reportError(withUndefinedRetry: error)
        }
    }

    // MARK: Restore

    private func restoreManifestIfNecessary() {
        var manifestVersion: UInt64?
        databaseStorage.read { transaction in
            manifestVersion = StorageServiceOperation.manifestVersion(transaction: transaction)
        }

        guard manifestVersion == nil else {
            // Nothing to do, we already have a local manifest
            return
        }

        StorageService.fetchManifest().done(on: .global()) { manifest in
            guard let manifest = manifest else {
                // There is no existing manifest, we're done!
                return self.reportSuccess()
            }

            self.mergeExistingManifestWithNewManifest(manifest, backupAfterSuccess: false)
        }.catch { error in
            owsFailDebug("received unexpected error while fetching manifest \(error)")
            let retryableError = error as NSError
            retryableError.isRetryable = true
            self.reportError(withUndefinedRetry: retryableError)
        }
    }

    // MARK: - Conflict Resolution

    private func mergeExistingManifestWithNewManifest(_ manifest: StorageServiceProtoManifestRecord, backupAfterSuccess: Bool) {
        var identifierMap: BidirectionalDictionary<AccountId, StorageService.ContactIdentifier> = [:]
        var pendingChanges: [AccountId: ChangeState] = [:]

        databaseStorage.read { transaction in
            identifierMap = StorageServiceOperation.accountToIdentifierMap(transaction: transaction)
            pendingChanges = StorageServiceOperation.accountChangeMap(transaction: transaction)
        }

        // Fetch all the contacts in the new manifest and resolve any conflicts appropriately.
        StorageService.fetchContacts(for: manifest.keys.map { .init(data: $0) }).done(on: .global()) { contacts in
            self.databaseStorage.write { transaction in
                for contact in contacts {
                    switch contact.mergeWithExisting(transaction: transaction) {
                    case .invalid:
                        // This contact record was invalid, ignore it.
                        // we'll clear it out in the next backup.
                        break

                    case .needsUpdate(let accountId):
                        // our local version was newer, flag this account as needing a sync
                        pendingChanges[accountId] = .updated

                    case .resolved(let accountId):
                        // update the mapping, this could be a new account
                        identifierMap[accountId] = contact.contactIdentifier
                    }
                }

                StorageServiceOperation.setAccountChangeMap(pendingChanges, transaction: transaction)
                StorageServiceOperation.setManifestVersion(manifest.version, transaction: transaction)
                StorageServiceOperation.setAccountToIdentifierMap(identifierMap, transaction: transaction)

                if backupAfterSuccess { self.addDependency(StorageServiceOperation(mode: .backup)) }

                self.reportSuccess()
            }
        }.catch { error in
            owsFailDebug("received unexpected error while fetching contacts \(error)")
            let retryableError = error as NSError
            retryableError.isRetryable = true
            self.reportError(withUndefinedRetry: retryableError)
        }
    }

    // MARK: - Accessors

    private static let accountToIdentifierMapKey = "accountToIdentifierMap"
    private static let accountChangeMapKey = "accountChangeMap"
    private static let manifestVersionKey = "manifestVersion"

    private static func manifestVersion(transaction: SDSAnyReadTransaction) -> UInt64? {
        return keyValueStore.getUInt64(manifestVersionKey, transaction: transaction)
    }

    private static func setManifestVersion( _ verison: UInt64, transaction: SDSAnyWriteTransaction) {
        keyValueStore.setUInt64(verison, key: manifestVersionKey, transaction: transaction)
    }

    private static func accountToIdentifierMap(transaction: SDSAnyReadTransaction) -> BidirectionalDictionary<AccountId, StorageService.ContactIdentifier> {
        let accountIdToIdentifierData = keyValueStore.getObject(accountToIdentifierMapKey, transaction: transaction) as? BidirectionalDictionary<AccountId, Data> ?? [:]
        return accountIdToIdentifierData.mapValues { .init(data: $0) }
    }

    private static func setAccountToIdentifierMap( _ map: BidirectionalDictionary<AccountId, StorageService.ContactIdentifier>, transaction: SDSAnyWriteTransaction) {
        keyValueStore.setObject(map.mapValues { $0.data }, key: accountToIdentifierMapKey, transaction: transaction)
    }

    private enum ChangeState: Int {
        case unchanged = 0
        case updated = 1
        case deleted = 2
    }
    private static func accountChangeMap(transaction: SDSAnyReadTransaction) -> [AccountId: ChangeState] {
        let accountIdToIdentifierData = keyValueStore.getObject(accountChangeMapKey, transaction: transaction) as? [AccountId: Int] ?? [:]
        return accountIdToIdentifierData.compactMapValues { ChangeState(rawValue: $0) }
    }

    private static func setAccountChangeMap(_ map: [AccountId: ChangeState], transaction: SDSAnyWriteTransaction) {
        keyValueStore.setObject(map.mapValues { $0.rawValue }, key: accountChangeMapKey, transaction: transaction)
    }
}
