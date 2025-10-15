import SwiftUI

struct DefaultBookCoverView: View {
    let width: CGFloat
    let height: CGFloat
    let showTitle: Bool
    let title: String?
    
    init(width: CGFloat = 140, height: CGFloat = 200, showTitle: Bool = false, title: String? = nil) {
        self.width = width
        self.height = height
        self.showTitle = showTitle
        self.title = title
    }
    
    var body: some View {
        ZStack {
            // 基礎背景漸變
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.1),
                    Color.gray.opacity(0.2),
                    Color.gray.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 裝飾性元素
            GeometryReader { geometry in
                // 背景紋理線條
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 1, height: geometry.size.height)
                        .offset(x: CGFloat(index) * (geometry.size.width / 7))
                }
                
                // 頂部裝飾條
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 3)
                    .offset(y: geometry.size.height * 0.15)
                
                // 底部裝飾條
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 3)
                    .offset(y: geometry.size.height * 0.85)
                
                // 中央書本圖標區域
                VStack(spacing: 8) {
                    Spacer()
                    
                    // 書本圖標
                    VStack(spacing: 4) {
                        // 書本主體
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.25)
                            .overlay(
                                // 書脊線
                                VStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 1)
                                        .offset(x: -geometry.size.width * 0.1)
                                    
                                    // 模擬文字線條
                                    ForEach(0..<4, id: \.self) { lineIndex in
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: geometry.size.width * 0.25, height: 1)
                                            .offset(y: CGFloat(lineIndex - 1) * 4)
                                    }
                                }
                            )
                        
                        // BOOK 文字
                        Text("BOOK")
                            .font(.system(size: min(geometry.size.width * 0.08, 12), weight: .medium, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                            .tracking(1)
                    }
                    
                    // 如果需要顯示標題
                    if showTitle, let title = title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: min(geometry.size.width * 0.06, 10), weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                }
            }
            
            // 邊框
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
        .frame(width: width, height: height)
        .cornerRadius(6)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 1, y: 1)
    }
    
    // 靜態方法：生成 UIImage
    static func generateUIImage(width: CGFloat = 140, height: CGFloat = 200, title: String? = nil) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        return renderer.image { context in
            // 背景漸變
            let colors = [
                UIColor.systemGray6.cgColor,
                UIColor.systemGray5.cgColor,
                UIColor.systemGray6.cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: width, y: height), options: [])
            
            // 邊框
            context.cgContext.setStrokeColor(UIColor.systemGray4.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(CGRect(x: 0.5, y: 0.5, width: width - 1, height: height - 1))
            
            // 背景紋理線條
            context.cgContext.setStrokeColor(UIColor.systemGray5.cgColor)
            context.cgContext.setLineWidth(0.5)
            for i in 0..<8 {
                let x = CGFloat(i) * (width / 7)
                context.cgContext.move(to: CGPoint(x: x, y: 0))
                context.cgContext.addLine(to: CGPoint(x: x, y: height))
                context.cgContext.strokePath()
            }
            
            // 頂部和底部裝飾條
            context.cgContext.setFillColor(UIColor.systemGray4.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: height * 0.15, width: width, height: 2))
            context.cgContext.fill(CGRect(x: 0, y: height * 0.85, width: width, height: 2))
            
            // 書本圖標
            let bookRect = CGRect(x: width * 0.3, y: height * 0.35, width: width * 0.4, height: height * 0.25)
            context.cgContext.setFillColor(UIColor.systemGray3.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: bookRect.minX - 2, y: bookRect.minY - 2, width: bookRect.width + 4, height: bookRect.height + 4))
            context.cgContext.setFillColor(UIColor.systemGray4.cgColor)
            context.cgContext.fill(bookRect)
            
            // 書脊線
            context.cgContext.setStrokeColor(UIColor.systemGray3.cgColor)
            context.cgContext.setLineWidth(1)
            let spineX = bookRect.minX + bookRect.width * 0.2
            context.cgContext.move(to: CGPoint(x: spineX, y: bookRect.minY))
            context.cgContext.addLine(to: CGPoint(x: spineX, y: bookRect.maxY))
            context.cgContext.strokePath()
            
            // 模擬文字線條
            context.cgContext.setStrokeColor(UIColor.systemGray2.cgColor)
            context.cgContext.setLineWidth(0.5)
            for i in 0..<4 {
                let lineY = bookRect.midY + (CGFloat(i) - 1.5) * 3
                let lineLength = [0.8, 0.6, 0.75, 0.5][i] * bookRect.width * 0.6
                context.cgContext.move(to: CGPoint(x: spineX + 4, y: lineY))
                context.cgContext.addLine(to: CGPoint(x: spineX + 4 + lineLength, y: lineY))
                context.cgContext.strokePath()
            }
            
            // BOOK 文字
            let bookText = "BOOK"
            let font = UIFont.systemFont(ofSize: min(width * 0.08, 12), weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.systemGray3
            ]
            
            let textSize = bookText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (width - textSize.width) / 2,
                y: height * 0.7,
                width: textSize.width,
                height: textSize.height
            )
            
            bookText.draw(in: textRect, withAttributes: attributes)
            
            // 如果有標題，顯示標題
            if let title = title, !title.isEmpty {
                let titleFont = UIFont.systemFont(ofSize: min(width * 0.06, 10), weight: .regular)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.systemGray2
                ]
                
                let titleText = title.count > 20 ? String(title.prefix(20)) + "..." : title
                let titleSize = titleText.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: (width - titleSize.width) / 2,
                    y: height * 0.78,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                titleText.draw(in: titleRect, withAttributes: titleAttributes)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 15) {
            // 基本版本
            DefaultBookCoverView()
            
            // 帶標題版本
            DefaultBookCoverView(showTitle: true, title: "Programming 101")
            
            // 小尺寸版本
            DefaultBookCoverView(width: 80, height: 120)
        }
        
        HStack(spacing: 15) {
            // 不同比例
            DefaultBookCoverView(width: 100, height: 150, showTitle: true, title: "Long Book Title Example")
            
            // Dashboard 尺寸
            DefaultBookCoverView(width: 40, height: 50)
            
            // 大尺寸
            DefaultBookCoverView(width: 200, height: 280, showTitle: true, title: "Large Cover")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
