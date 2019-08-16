//
//  CrashManager.swift
//  CrashManagerDemo
//
//  Created by Pikachu on 2019/8/14.
//  Copyright © 2019 Rogdoll. All rights reserved.
//

import Foundation
import CMCKit

// MARK: - Static functions & properties
private let kFileManager = FileManager.default
private let kPathExtension = ".txt"
private let kCacheDirectory = "CrashManager"

private let kDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyMMdd-HHmmss"
    return dateFormatter
}()

/// 地址偏移
private var kAdressOffset: UInt32 {
    return (0..<_dyld_image_count()).first(where: { _dyld_get_image_header($0)?.pointee.filetype == UInt32(MH_EXECUTE) }) ?? 0
}
/// 堆栈信息
private var kCallStackSymbols: [String] {
//    var callstack = [UnsafeMutableRawPointer?](repeating: nil, count: 128)
//    let frames = backtrace(&callstack, Int32(callstack.count))
//    guard let strs = backtrace_symbols(callstack, frames) else { return [] }
//    return (0..<frames).map({ strs[Int($0)] }).compactMap({ $0 }).map({ String(cString: $0) })
    
    return Thread.callStackSymbols.map({ "\($0)" })
}

/// 异常捕获
private func uncaughtExceptionHandler(exception: NSException) {
    let callStackSymbols = exception.callStackSymbols.joined(separator: "\n")
    let reason = exception.reason?.description ?? "null"
    let name = exception.name.rawValue
    
    let crash =
    """
    Stack: \(String(format: "SlideAdress:0x%0x", kAdressOffset))
    Name: \(name)
    Reason: \(reason)
    
    \(callStackSymbols)
    """
    
    CrashManager.save(crash: crash, at: CrashManager.CrashType.exception.rawValue)
}

/// 信号捕获
private func signalExceptionHandler(signal: Int32) {
    let crash = "Stack: \(String(format: "SlideAdress:0x%0x", kAdressOffset))\n" + kCallStackSymbols.joined(separator: "\n")
    CrashManager.save(crash: crash, at: CrashManager.CrashType.signal.rawValue)
    exit(signal)
}

// MARK: - ---  CrashManager  ---
/// 若导入多个异常捕获工具会覆盖回调。
@objc(PKCrashManager) open class CrashManager: NSObject {
    public static var singals: Set<Int32> = [] {
        didSet {
            if oldValue.count == singals.count, oldValue.union(singals).count != oldValue.count { return }
            let _ = oldValue.map({ signal($0, SIG_DFL) })
            let _ = singals.map({ signal($0, signalExceptionHandler)})
        }
    }
}

// MARK: - Public
extension CrashManager {
    public enum CrashType: String {
        case signal = "Signal"
        case exception = "Exception"
    }
    
    /// 缓存总路径
    @objc open class var cachesDirectory: NSString? {
        let cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first as NSString?
        return cache?.appendingPathComponent(kCacheDirectory) as NSString?
    }
    
    /// 根据传入的异常类型,返回不同异常具体的路径
    open class func crashDirectory(with directory: String) -> String? {
        return cachesDirectory?.appendingPathComponent(directory)
    }
    
    public typealias CrashHandle = ([String]) -> ()
    @objc(installWithHandle:) open class func install(_ handle: CrashHandle? = nil) {
        DispatchQueue.global().async {
            let infos = crashInfos()
            if infos.count > 0 {
                handle?(infos)
            }
            deleteAllFiles()
        }
        
        NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
        singals = [
            SIGABRT,
            SIGSEGV,
            SIGBUS,
            SIGTRAP,
            SIGILL,
            SIGHUP,
            SIGINT,
            SIGQUIT,
            SIGFPE,
            SIGPIPE,
        ]
    }
    
    @objc open class func uninstall() {
        NSSetUncaughtExceptionHandler(nil)
        singals = []
    }
}

// MARK: Save
extension CrashManager {
    /// 保存
    @objc(saveCrashInfo:atDirectory:) open class func save(crash info: String, at directory: String) {
        guard let crashPath = crashDirectory(with: directory) else { return }
        
        if !kFileManager.fileExists(atPath: crashPath) {
            do {
                try kFileManager.createDirectory(atPath: crashPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }

        let dateString = kDateFormatter.string(from: Date())
        let crashFilePath = crashPath + "/" + dateString + kPathExtension
        try? info.write(toFile: crashFilePath, atomically: true, encoding: .utf8)
    }
}

// MARK: Get
extension CrashManager {
    /// 获取所有crash文件
    @objc(crashFilesAtDirectory:) static func crashFiles(at directory: String) -> [String] {
        guard let crashPath = crashDirectory(with: directory) else { return [] }
        guard let list = try? kFileManager.contentsOfDirectory(atPath: crashPath) else { return [] }
        return list.filter({ $0.range(of: kPathExtension) != nil }).map({ crashPath + "/" + $0 })
    }
    
    /// 读取所有crash文件信息
    @objc open class func crashInfos() -> [String] {
        let crashs = crashFiles(at: CrashType.signal.rawValue) + crashFiles(at: CrashType.exception.rawValue)
        return crashs.map({ try? String(contentsOfFile: $0, encoding: .utf8) }).compactMap({ $0 })
    }
    
    /// 读取某个crash文件
    @objc(readCrashByFileName:directory:) open class func readCrash(by fileName: String, at directory: String) -> String? {
        guard let crashPath = crashDirectory(with: directory) else { return nil }
        let filePath = crashPath + "/" + fileName
        return try? String(contentsOfFile: filePath, encoding: .utf8)
    }
}

// MARK: Delete
extension CrashManager {
    /// 删除所有crash文件
    @objc open class func deleteAllFiles() {
        let crashs = crashFiles(at: CrashType.signal.rawValue) + crashFiles(at: CrashType.exception.rawValue)
        let _ = crashs.map({ try? kFileManager.removeItem(atPath: $0) })
    }
    
    /// 删除某个crash文件
    @objc(deleteCrashByFileName:directory:) open class func deleteCrash(by fileName: String, at directory: String) {
        guard let crashPath = crashDirectory(with: directory) else { return }
        let filePath = crashPath + "/" + fileName
        try? kFileManager.removeItem(atPath: filePath)
    }
}
