import SwiftUI
import Amplify

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var showNewProjectSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(projects, id: \.id) { project in
                    NavigationLink(destination: ChatView(project: project)) {
                        Text(project.name)
                    }
                }
            }
            .navigationBarTitle("Inspector AI", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    showNewProjectSheet = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheet { newName in
                    createProject(name: newName)
                }
            }
            .onAppear(perform: fetchProjects)
        }
    }

    private func fetchProjects() {
        Task {
            do {
                let list = try await Amplify.DataStore.query(Project.self)
                let sorted = list.sorted { $0.name < $1.name }
                await MainActor.run {
                    self.projects = sorted
                }
            } catch {
                print("プロジェクト取得エラー: \(error)")
            }
        }
    }

    private func createProject(name: String) {
        let newProject = Project(name: name)
        Task {
            do {
                try await Amplify.DataStore.save(newProject)
                fetchProjects() // 作成後に再取得
            } catch {
                print("プロジェクト保存エラー: \(error)")
            }
        }
    }
}

struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView()
    }
}

