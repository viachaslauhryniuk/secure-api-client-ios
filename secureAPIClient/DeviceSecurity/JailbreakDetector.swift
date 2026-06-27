import Foundation
import UIKit

@MainActor
enum JailbreakDetector {
    static var isCompromisedDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return hasSuspiciousPaths() || canOpenCydia() || isDebuggerAttached()
        #endif
    }

    private static func hasSuspiciousPaths() -> Bool {
        let suspiciousPaths: [String] = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/Applications/Sileo.app",
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }

    private static func canOpenCydia() -> Bool {
        guard let url = URL(string: "cydia://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
