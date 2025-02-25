//
//  NewProjectSheet.swift
//
import SwiftUI

struct NewProjectSheet: View {
    // プロジェクト作成時のクロージャ
    let onProjectCreated: (String) -> Void
    @State private var projectName = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プロジェクト名を入力")) {
                    TextField("プロジェクト名", text: $projectName)
                }
            }
            .navigationBarTitle("新規プロジェクト作成", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("作成") {
                    onProjectCreated(projectName)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
    }
}

