//
//  ValidateCommand.swift
//  IBLinterKit
//
//  Created by SaitoYuta on 2017/12/13.
//

import Result
import Foundation
import IBDecodable
import IBLinterKit
import Commandant
import PathKit

struct ValidateCommand: CommandProtocol {
    typealias Options = ValidateOptions
    typealias ClientError = Options.ClientError

    let verb: String = "lint"
    var function: String = "Print lint warnings and errors (default command)"

    func run(_ options: ValidateCommand.Options) -> Result<(), ValidateCommand.ClientError> {
        let workDirectoryString = options.path ?? FileManager.default.currentDirectoryPath
        let workDirectory = URL(fileURLWithPath: workDirectoryString)
        guard FileManager.default.isDirectory(workDirectory.path) else {
            fatalError("\(workDirectoryString) is not directory.")
        }
        let config = (try? Config.load(from: workDirectory)) ?? Config.default
        if config.disableWhileBuildingForIB &&
            ProcessInfo.processInfo.compiledForInterfaceBuilder {
            return .success(())
        }
        let validator = Validator()
        let violations = validator.validate(workDirectory: workDirectory, config: config)

        let reporter = Reporters.reporter(from: options.reporter ?? config.reporter)
        let report = reporter.generateReport(violations: violations)
        print(report)

        let numberOfSeriousViolations = violations.filter { $0.level == .error }.count
        if numberOfSeriousViolations > 0 {
            exit(2)
        } else {
            return .success(())
        }
    }
}

struct ValidateOptions: OptionsProtocol {
    typealias ClientError = CommandantError<()>

    let path: String?
    let reporter: String?
    let iblinterFilePath: String?

    static func create(_ path: String?) -> (_ reporter: String?) -> (_ script: String?) -> ValidateOptions {
        return { reporter in
            return { script in
                self.init(path: path, reporter: reporter, iblinterFilePath: script)
            }
        }
    }

    static func evaluate(_ mode: CommandMode) -> Result<ValidateCommand.Options, CommandantError<ValidateOptions.ClientError>> {
        return create
            <*> mode <| Option(key: "path", defaultValue: nil, usage: "validate project root directory")
            <*> mode <| Option(key: "reporter", defaultValue: nil, usage: "the reporter used to log errors and warnings")
            <*> mode <| Option(key: "script", defaultValue: nil, usage: "custom IBLinterfile.swift")
    }
}

extension ProcessInfo {
    var compiledForInterfaceBuilder: Bool {
        return environment["COMPILED_FOR_INTERFACE_BUILDER"] != nil
    }
}

