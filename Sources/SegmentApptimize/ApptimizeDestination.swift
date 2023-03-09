//
//  ApptimizeDestination.swift
//  ApptimizeDestination
//
//  Copyright © Urban Airship Inc., d/b/a Airship.
//

import Foundation
import Segment
import Apptimize

public class ApptimizeDestination: DestinationPlugin {
    private static let kScreenViewedFormat = "Viewed %@ screen"
    private static var SharedNotificationToken: Any?
    
    public let timeline = Timeline()
    public let type = PluginType.destination
    
    public let key = "Apptimize"
    public var analytics: Analytics? = nil
    
    private var settings: ApptimizeSettings?
        
    public init() { }
    
    deinit {
        unsubscribe()
    }

    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        
        guard let settings: ApptimizeSettings = settings.integrationSettings(forPlugin: self) else {
            return
        }
        
        self.settings = settings
        
        let start = {
            Apptimize.start(withApplicationKey: settings.appKey, options: settings.asDictionary())
            
            if let export = settings.trackExperimentParticipationToSegment, export {
                self.subscribeForEventParticipation()
            }
        }
        
        if Thread.isMainThread {
            start()
        } else {
            DispatchQueue.main.async(execute: start)
        }
    }
    
    private func subscribeForEventParticipation() {
        guard Self.SharedNotificationToken == nil else {
            return
        }
        
        Self.SharedNotificationToken = NotificationCenter.default.addObserver(
            forName: .ApptimizeParticipatedInExperiment,
            object: nil,
            queue: .main) { [analytics = self.analytics] notification in
                guard
                    let particiaption = notification.userInfo?[ApptimizeFirstParticipationKey],
                    let isFirstParticipation = particiaption as? Bool,
                    isFirstParticipation,
                    let info = notification.userInfo?[ApptimizeTestInfoKey],
                    let testInfo = info as? ApptimizeTestInfo,
                    let analytics = analytics else {
                    return
                }
                
                analytics.track(
                    name: "Experiment Viewed",
                    properties: [
                        "experimentId": testInfo.testID().intValue,
                        "experimentName": testInfo.testName(),
                        "variationId": testInfo.enrolledVariantID().intValue,
                        "variationName": testInfo.enrolledVariantName()
                    ])
            }
    }
    
    private func unsubscribe() {
        if let token = Self.SharedNotificationToken {
            NotificationCenter.default.removeObserver(token)
        }
        
        Self.SharedNotificationToken = nil
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        Apptimize.setCustomerUserID(event.userId)
        
        if let params = event.traits?.dictionaryValue {
            Apptimize.seg_setUserAttributes(from: params)
        }
        
        return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        Apptimize.seg_track(event.event, attributes: event.properties?.dictionaryValue)
        
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        
        guard let screen = event.name else {
            return event
        }
        
        let name = String(format: Self.kScreenViewedFormat, screen)
        Apptimize.seg_track(name, attributes: event.properties?.dictionaryValue)
        
        return event
    }
}

extension ApptimizeDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}

private struct ApptimizeSettings: Codable {
    let appKey: String
    let trackExperimentParticipationToSegment: Bool?
    let isEU: Bool?
    let devicePairingEnabled: Bool?
    let logLevel: String?
    let delayUntilTestsAreAvailable: Int?
    let thirdPartyEventsImportEnabled: Bool?
    let thirdPartyEventsExportEnabled: Bool?
    let forceVariantsShowWinnersAndInstantUpdates: Bool?
    let applicationGroup: String?
    
    enum CodingKeys: String, CodingKey {
        case appKey = "appkey"
        case trackExperimentParticipationToSegment = "listen"
        case isEU = "apptimizeEuDataCenter"
        case devicePairingEnabled = "devicePairingEnabled"
        case logLevel = "logLevel"
        case delayUntilTestsAreAvailable = "delayUntilTestsAreAvailable"
        case thirdPartyEventsImportEnabled = "thirdPartyEventsImportEnabled"
        case thirdPartyEventsExportEnabled = "thirdPartyEventsExportEnabled"
        case forceVariantsShowWinnersAndInstantUpdates = "forceVariantsShowWinnersAndInstantUpdates"
        case applicationGroup = "applicationGroup"
    }
    
    func asDictionary() -> [String: Any] {
        let region = (isEU ?? false) ? ApptimizeServerRegionEUCS : ApptimizeServerRegionDefault
        
        return [
            ApptimizeServerRegionOption: region,
            ApptimizeDevicePairingOption: self.devicePairingEnabled ?? true,
            ApptimizeLogLevelOption: self.logLevel ?? ApptimizeLogLevelError,
            ApptimizeDelayUntilTestsAreAvailableOption: self.delayUntilTestsAreAvailable ?? 0,
            ApptimizeEnableThirdPartyEventImportingOption: self.thirdPartyEventsImportEnabled ?? true,
            ApptimizeEnableThirdPartyEventExportingOption: self.thirdPartyEventsExportEnabled ?? true,
            ApptimizeForceVariantsShowWinnersAndInstantUpdatesOption: self.forceVariantsShowWinnersAndInstantUpdates ?? false,
            ApptimizeAppGroupOption: self.applicationGroup ?? ""
        ]
    }
}
