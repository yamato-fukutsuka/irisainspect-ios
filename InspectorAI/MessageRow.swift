import SwiftUI

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                HStack(spacing: 4) {
                    // メッセージバブル
                    Text(message.content)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .overlay(
                            Triangle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                                .rotationEffect(Angle(degrees: 90))
                                .offset(x: 5, y: 0),
                            alignment: .bottomTrailing
                        )
                    // タイムスタンプ（横に表示、細字、枠なし）
                    if let date = message.createdAt?.foundationDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    // タイムスタンプ
                    if let date = message.createdAt?.foundationDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    // メッセージバブル
                    Text(message.content)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(15)
                        .overlay(
                            Triangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 10, height: 10)
                                .rotationEffect(Angle(degrees: -90))
                                .offset(x: -5, y: 0),
                            alignment: .bottomLeading
                        )
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        // 表示例: 14:23
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

