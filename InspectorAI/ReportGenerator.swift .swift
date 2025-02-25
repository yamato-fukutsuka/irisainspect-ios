// ReportGenerator.swift
import Foundation
import PDFKit
import UIKit

class ReportGenerator {
    func generateReportHTML(analysisResult: String, timestamp: Date) -> String {
        // テンプレートHTMLをBundleから読み込む例。ファイル名: "reportTemplate.html"
        guard let url = Bundle.main.url(forResource: "reportTemplate", withExtension: "html"),
              let template = try? String(contentsOf: url) else {
            return "<html><body><p>No Template</p></body></html>"
        }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var html = template
        html = html.replacingOccurrences(of: "{{analysisResult}}", with: analysisResult)
        html = html.replacingOccurrences(of: "{{timestamp}}", with: df.string(from: timestamp))
        return html
    }
    
    func generatePDF(from html: String) -> Data? {
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            fmt.draw(in: page, forPageAt: 0)
        }
        return data
    }
    
    func generateReport(analysisResult: String) -> Data? {
        let html = generateReportHTML(analysisResult: analysisResult, timestamp: Date())
        return generatePDF(from: html)
    }
}

