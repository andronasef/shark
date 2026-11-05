import Foundation
import Testing
@testable import Shark

@MainActor
struct VolumeEjectTests {
    @Test func eligibilityExcludesStartupAndUnknownVolumes() {
        func eligible(_ path: String, ejectable: Bool = false, removable: Bool = false,
                      internalVolume: Bool? = nil, local: Bool? = nil) -> Bool {
            VolumeEjectService.canEject(URL(fileURLWithPath: path), isEjectable: ejectable,
                isRemovable: removable, isInternal: internalVolume, isLocal: local)
        }
        #expect(!eligible("/", ejectable: true, removable: true, internalVolume: false))
        #expect(!eligible("/System/Volumes/Data", ejectable: true, internalVolume: false))
        #expect(!eligible("/Volumes/Unknown"))
        #expect(!eligible("/Volumes/Internal", internalVolume: true, local: true))
        #expect(eligible("/Volumes/Image", ejectable: true))
        #expect(eligible("/Volumes/USB", removable: true))
        #expect(eligible("/Volumes/ExternalSSD", internalVolume: false, local: true))
        #expect(eligible("/Volumes/Share", local: false))
    }

    @Test func startupVolumeNeverReachesUnmountOperation() async throws {
        try await VolumeEjectService().eject(URL(fileURLWithPath: "/")) { _ in
            Issue.record("Startup disk must never be ejected")
        }
    }

    @Test func successfulAndFailedEjectionsReleaseBusyState() async throws {
        let service = VolumeEjectService()
        let url = URL(fileURLWithPath: "/Volumes/Test")
        try await service.eject(url) { target in
            #expect(target == url)
            #expect(await service.ejecting.contains(url))
        }
        #expect(service.ejecting.isEmpty)
        struct Busy: Error {}
        do {
            try await service.eject(url) { _ in throw Busy() }
            Issue.record("Unmount failures must reach the UI")
        } catch is Busy { }
        #expect(service.ejecting.isEmpty)
    }
}
