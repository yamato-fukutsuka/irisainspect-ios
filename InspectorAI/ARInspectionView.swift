// ARInspectionView.swift
import SwiftUI
import ARKit


struct ARInspectionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let project: Project
    
    @State private var isScanning = false
    @State private var showSlowMessage = false
    
    var body: some View {
        ZStack {
            ARRealityView(
                isScanning: $isScanning,
                project: project,
                onFinishUpload: { message in
                    print("ARデータアップロード完了: \(message)")
                    // 終了してチャット画面に戻る
                    presentationMode.wrappedValue.dismiss()
                },
                onFastMovement: { isFast in
                    self.showSlowMessage = isFast
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        isScanning.toggle()
                    }) {
                        Text(isScanning ? "停止" : "撮影開始")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isScanning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding([.top, .leading, .trailing], 16)
                    }
                }
                Spacer()
            }
            
            if showSlowMessage {
                VStack {
                    Text("ゆっくり動かしてください")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.top, 100)
                    Spacer()
                }
            }
        }
        .navigationBarTitle("AR 撮影", displayMode: .inline)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

