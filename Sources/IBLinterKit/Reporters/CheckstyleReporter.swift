//source: realm/Swiftlint

public struct CheckstyleReporter: Reporter {
    public static let identifier = "checkstyle"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as Checkstyle XML."
    }

    public static func generateReport(violations: [Violation]) -> String {
        return [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            violations
                .group(by: { ($0.location.file ?? "<nopath>").escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map(generateForViolationFile).joined(),
            "\n</checkstyle>"
        ].joined()
    }

    private static func generateForViolationFile(_ file: String, violations: [Violation]) -> String {
        return [
            "\n\t<file name=\"", file, "\">\n",
            violations.map(generateForSingleViolation).joined(),
            "\t</file>"
        ].joined()
    }

    private static func generateForSingleViolation(violation: Violation) -> String {
//        let line: Int = violation.location.line ?? 0
//        let col: Int = violation.location.character ?? 0
        let severity: String = violation.level.rawValue
        let reason: String = violation.message.escapedForXML()
//        let identifier: String = violation.ruleDescription.identifier
//        let source: String = "iblinter.rules.\(identifier)".escapedForXML()
        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"", severity, "\" ",
            "message=\"", reason, "\"\n"//,
//            "source=\"\(source)\"/>\n"
        ].joined()
    }
}
