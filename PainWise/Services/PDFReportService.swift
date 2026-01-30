import Foundation
import PDFKit
import SwiftUI

@MainActor
final class PDFReportService {
    static let shared = PDFReportService()

    private init() {}

    // MARK: - Generate PDF Report

    func generateReport(
        records: [PainRecord],
        correlations: [CorrelationResult],
        userName: String = "田中さん"
    ) -> Data? {
        let pageWidth: CGFloat = 595.2  // A4 width in points
        let pageHeight: CGFloat = 841.8 // A4 height in points
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "PainWise",
            kCGPDFContextAuthor: userName,
            kCGPDFContextTitle: L10n.pdfReportTitle
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            // Page 1: Summary
            context.beginPage()
            drawSummaryPage(
                context: context,
                pageRect: pageRect,
                margin: margin,
                records: records,
                correlations: correlations,
                userName: userName
            )

            // Page 2: Record Details (if many records)
            if records.count > 5 {
                context.beginPage()
                drawRecordsPage(
                    context: context,
                    pageRect: pageRect,
                    margin: margin,
                    records: records
                )
            }
        }

        return data
    }

    // MARK: - Draw Summary Page

    private func drawSummaryPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        margin: CGFloat,
        records: [PainRecord],
        correlations: [CorrelationResult],
        userName: String
    ) {
        var yPosition: CGFloat = margin
        let contentWidth = pageRect.width - (margin * 2)

        // Header with logo placeholder
        let headerRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 60)
        drawHeader(in: headerRect, userName: userName)
        yPosition += 80

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 1.0)
        ]
        let title = L10n.pdfReportTitle
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
        yPosition += 40

        // Date range
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年M月d日"

        let dateRange: String
        if let firstDate = records.last?.timestamp, let lastDate = records.first?.timestamp {
            dateRange = "\(dateFormatter.string(from: firstDate)) 〜 \(dateFormatter.string(from: lastDate))"
        } else {
            dateRange = dateFormatter.string(from: Date())
        }

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        dateRange.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
        yPosition += 30

        // Summary Statistics Box
        yPosition = drawSummaryBox(
            at: CGPoint(x: margin, y: yPosition),
            width: contentWidth,
            records: records
        )
        yPosition += 20

        // Correlation Analysis Section
        if !correlations.isEmpty {
            yPosition = drawCorrelationSection(
                at: CGPoint(x: margin, y: yPosition),
                width: contentWidth,
                correlations: correlations
            )
            yPosition += 20
        }

        // Body Part Analysis
        yPosition = drawBodyPartSection(
            at: CGPoint(x: margin, y: yPosition),
            width: contentWidth,
            records: records
        )
        yPosition += 20

        // Recent Records Table
        drawRecentRecordsTable(
            at: CGPoint(x: margin, y: yPosition),
            width: contentWidth,
            records: Array(records.prefix(5))
        )

        // Footer
        drawFooter(pageRect: pageRect, margin: margin)
    }

    // MARK: - Draw Header

    private func drawHeader(in rect: CGRect, userName: String) {
        // App name
        let appNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 1.0)
        ]
        "PainWise".draw(at: CGPoint(x: rect.minX, y: rect.minY), withAttributes: appNameAttributes)

        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        L10n.appSubtitle.draw(at: CGPoint(x: rect.minX, y: rect.minY + 25), withAttributes: subtitleAttributes)

        // User name on right
        let userAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let userText = L10n.pdfPatientName(userName)
        let userSize = userText.size(withAttributes: userAttributes)
        userText.draw(at: CGPoint(x: rect.maxX - userSize.width, y: rect.minY + 10), withAttributes: userAttributes)

        // Generated date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let generatedText = L10n.pdfGeneratedDate(dateFormatter.string(from: Date()))
        let generatedSize = generatedText.size(withAttributes: subtitleAttributes)
        generatedText.draw(at: CGPoint(x: rect.maxX - generatedSize.width, y: rect.minY + 30), withAttributes: subtitleAttributes)
    }

    // MARK: - Draw Summary Box

    private func drawSummaryBox(at point: CGPoint, width: CGFloat, records: [PainRecord]) -> CGFloat {
        let boxHeight: CGFloat = 100
        let boxRect = CGRect(x: point.x, y: point.y, width: width, height: boxHeight)

        // Background
        let path = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1.0).setFill()
        path.fill()

        // Border
        UIColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 0.3).setStroke()
        path.lineWidth = 1
        path.stroke()

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        L10n.pdfSummary.draw(at: CGPoint(x: point.x + 15, y: point.y + 10), withAttributes: titleAttributes)

        // Stats
        let statsY = point.y + 35
        let statWidth = width / 4

        let stats = [
            (L10n.pdfRecordCount, "\(records.count)"),
            (L10n.pdfAvgPain, String(format: "%.1f", records.isEmpty ? 0 : Double(records.map { $0.painLevel }.reduce(0, +)) / Double(records.count))),
            (L10n.pdfMaxPain, "\(records.map { $0.painLevel }.max() ?? 0)"),
            (L10n.pdfMinPain, "\(records.map { $0.painLevel }.min() ?? 0)")
        ]

        for (index, stat) in stats.enumerated() {
            let x = point.x + 15 + CGFloat(index) * statWidth

            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            stat.0.draw(at: CGPoint(x: x, y: statsY), withAttributes: labelAttributes)

            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 1.0)
            ]
            stat.1.draw(at: CGPoint(x: x, y: statsY + 15), withAttributes: valueAttributes)
        }

        return point.y + boxHeight
    }

    // MARK: - Draw Correlation Section

    private func drawCorrelationSection(at point: CGPoint, width: CGFloat, correlations: [CorrelationResult]) -> CGFloat {
        var yPos = point.y

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        L10n.pdfCorrelationAnalysis.draw(at: CGPoint(x: point.x, y: yPos), withAttributes: titleAttributes)
        yPos += 25

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 1.0)
        ]

        for correlation in correlations.prefix(4) {
            let text = "\(correlation.factor.localizedName): "
            text.draw(at: CGPoint(x: point.x + 10, y: yPos), withAttributes: labelAttributes)

            let valueText = String(format: "%.2f (\(correlation.strength.localizedName))", correlation.coefficient)
            let textSize = text.size(withAttributes: labelAttributes)
            valueText.draw(at: CGPoint(x: point.x + 10 + textSize.width, y: yPos), withAttributes: valueAttributes)

            yPos += 20
        }

        return yPos
    }

    // MARK: - Draw Body Part Section

    private func drawBodyPartSection(at point: CGPoint, width: CGFloat, records: [PainRecord]) -> CGFloat {
        var yPos = point.y

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        L10n.pdfBodyPartAnalysis.draw(at: CGPoint(x: point.x, y: yPos), withAttributes: titleAttributes)
        yPos += 25

        // Count body parts
        let bodyPartCounts = Dictionary(grouping: records.flatMap { $0.bodyParts }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        for (bodyPart, count) in bodyPartCounts.prefix(5) {
            let text = "• \(bodyPart.localizedName): \(count)"
            text.draw(at: CGPoint(x: point.x + 10, y: yPos), withAttributes: labelAttributes)
            yPos += 18
        }

        return yPos
    }

    // MARK: - Draw Recent Records Table

    private func drawRecentRecordsTable(at point: CGPoint, width: CGFloat, records: [PainRecord]) {
        var yPos = point.y

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        L10n.pdfRecentRecords.draw(at: CGPoint(x: point.x, y: yPos), withAttributes: titleAttributes)
        yPos += 25

        // Table header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        let columns: [(String, CGFloat)] = [
            (L10n.pdfDatetime, 0),
            (L10n.pdfPainLevel, 120),
            (L10n.pdfLocation, 200),
            (L10n.forecastCardPressure, 350)
        ]

        for (title, offset) in columns {
            title.draw(at: CGPoint(x: point.x + offset, y: yPos), withAttributes: headerAttributes)
        }
        yPos += 18

        // Separator line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: point.x, y: yPos))
        linePath.addLine(to: CGPoint(x: point.x + width, y: yPos))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        yPos += 5

        // Table rows
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "M/d HH:mm"

        for record in records {
            let dateText = dateFormatter.string(from: record.timestamp)
            dateText.draw(at: CGPoint(x: point.x, y: yPos), withAttributes: cellAttributes)

            let levelText = "\(record.painLevel)/10"
            levelText.draw(at: CGPoint(x: point.x + 120, y: yPos), withAttributes: cellAttributes)

            let partsText = record.bodyParts.prefix(2).map { $0.localizedName }.joined(separator: ", ")
            partsText.draw(at: CGPoint(x: point.x + 200, y: yPos), withAttributes: cellAttributes)

            let pressureText = record.weatherData.map { String(format: "%.0f hPa", $0.pressure) } ?? "-"
            pressureText.draw(at: CGPoint(x: point.x + 350, y: yPos), withAttributes: cellAttributes)

            yPos += 18
        }
    }

    // MARK: - Draw Records Page

    private func drawRecordsPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        margin: CGFloat,
        records: [PainRecord]
    ) {
        var yPosition: CGFloat = margin
        let contentWidth = pageRect.width - (margin * 2)

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.darkGray
        ]
        L10n.pdfAllRecords.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
        yPosition += 30

        drawRecentRecordsTable(
            at: CGPoint(x: margin, y: yPosition),
            width: contentWidth,
            records: records
        )

        drawFooter(pageRect: pageRect, margin: margin)
    }

    // MARK: - Draw Footer

    private func drawFooter(pageRect: CGRect, margin: CGFloat) {
        let footerY = pageRect.height - margin + 20

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]

        let footerText = L10n.pdfFooter
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerX = (pageRect.width - footerSize.width) / 2
        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - Save to Documents

    func saveReport(_ data: Data, fileName: String = "PainWise_Report") -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fullFileName = "\(fileName)_\(timestamp).pdf"

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(fullFileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
}
