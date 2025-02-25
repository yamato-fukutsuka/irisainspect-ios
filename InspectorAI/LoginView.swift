import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

enum AuthFlowState {
    case signIn, signUp, confirmSignUp
}

struct LoginView: View {
    @State private var authFlow: AuthFlowState = .signIn
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmationCode: String = ""
    @State private var isSignedIn: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationView {
            if isSignedIn {
                // ログイン成功後は ProjectListView を表示
                ProjectListView()
            } else {
                VStack(spacing: 20) {
                    Text("Inspector AI")
                        .font(.largeTitle)
                        .bold()
                    
                    // 現在の認証フローに応じた入力フォームを表示
                    switch authFlow {
                    case .signIn:
                        signInSection
                    case .signUp:
                        signUpSection
                    case .confirmSignUp:
                        confirmationSection
                    }
                }
                .padding()
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleAuthFlow) {
                            Text(authFlow == .signIn ? "新規登録" : "ログインへ")
                        }
                    }
                }
                // エラー発生時は Alert で詳細を表示
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("エラー"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch authFlow {
        case .signIn:
            return "ログイン"
        case .signUp:
            return "サインアップ"
        case .confirmSignUp:
            return "認証コード入力"
        }
    }
    
    private func toggleAuthFlow() {
        // エラー表示をリセットして認証フローを切り替え
        errorMessage = ""
        authFlow = (authFlow == .signIn) ? .signUp : .signIn
    }
    
    private var signInSection: some View {
        VStack(spacing: 20) {
            TextField("メールアドレス", text: $username)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("パスワード", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button {
                signIn()
            } label: {
                Text("ログイン")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
    
    private var signUpSection: some View {
        VStack(spacing: 20) {
            TextField("メールアドレス", text: $username)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("パスワード", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button {
                signUp()
            } label: {
                Text("登録")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
    }
    
    private var confirmationSection: some View {
        VStack(spacing: 20) {
            Text("認証コードを入力してください")
                .font(.headline)
            TextField("認証コード", text: $confirmationCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            Button {
                confirmSignUp()
            } label: {
                Text("確認")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - エラー内容を日本語に変換する関数
    private func translateError(_ error: Error) -> String {
        let errorDesc = error.localizedDescription
        if errorDesc.contains("User already exists") || errorDesc.contains("usernameExists") {
            return "アカウントは既に存在しています。既存のアカウントでログインしてください。"
        } else if errorDesc.contains("Invalid password") {
            return "パスワードが正しくありません。"
        } else if errorDesc.contains("User not found") {
            return "ユーザーが見つかりません。サインアップしてください。"
        } else if errorDesc.contains("confirmation code") {
            return "認証コードが正しくありません。再度確認してください。"
        } else if errorDesc.contains("AWS credentials") {
            return "認証情報の取得に失敗しました。再度ログインしてください。"
        } else {
            return "エラーが発生しました: \(errorDesc)"
        }
    }
    
    // MARK: - 認証処理
    
    private func signIn() {
        Task {
            await signInTask()
        }
    }
    
    private func signInTask() async {
        do {
            // 既にサインイン状態の場合はサインアウト
            let currentSession = try await Amplify.Auth.fetchAuthSession()
            if currentSession.isSignedIn {
                try await Amplify.Auth.signOut()
            }
            let signInResult = try await Amplify.Auth.signIn(username: username, password: password)
            if signInResult.isSignedIn {
                await MainActor.run {
                    isSignedIn = true
                }
            } else if case .confirmSignInWithSMSMFACode = signInResult.nextStep {
                await MainActor.run {
                    authFlow = .confirmSignUp
                    errorMessage = "SMS認証が必要です。認証コードを入力してください。"
                    showErrorAlert = true
                }
            } else {
                await MainActor.run {
                    errorMessage = "サインインに失敗しました。追加ステップが必要です。"
                    showErrorAlert = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = translateError(error)
                showErrorAlert = true
            }
        }
    }
    
    private func signUp() {
        Task {
            await signUpTask()
        }
    }
    
    private func signUpTask() async {
        let userAttributes = [AuthUserAttribute(.email, value: username)]
        do {
            let signUpResult = try await Amplify.Auth.signUp(
                username: username,
                password: password,
                options: .init(userAttributes: userAttributes)
            )
            print("サインアップ成功: \(signUpResult)")
            if case .confirmUser = signUpResult.nextStep {
                await MainActor.run {
                    authFlow = .confirmSignUp
                    errorMessage = ""
                }
            } else {
                await MainActor.run {
                    isSignedIn = true
                }
            }
        } catch {
            await MainActor.run {
                let errorDesc = translateError(error)
                // 既に存在する場合は、サインアップ失敗ではなくログイン画面に遷移する
                if errorDesc.contains("既に存在") {
                    errorMessage = "アカウントは既に存在しています。ログインしてください。"
                    authFlow = .signIn
                } else {
                    errorMessage = errorDesc
                }
                showErrorAlert = true
            }
        }
    }
    
    private func confirmSignUp() {
        Task {
            await confirmSignUpTask()
        }
    }
    
    private func confirmSignUpTask() async {
        do {
            let confirmResult = try await Amplify.Auth.confirmSignUp(
                for: username,
                confirmationCode: confirmationCode
            )
            if confirmResult.isSignUpComplete {
                await signInAfterConfirmation()
            } else {
                await MainActor.run {
                    errorMessage = "認証が完了していません。"
                    showErrorAlert = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = translateError(error)
                showErrorAlert = true
            }
        }
    }
    
    private func signInAfterConfirmation() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                await MainActor.run {
                    isSignedIn = true
                }
            } else {
                let signInResult = try await Amplify.Auth.signIn(username: username, password: password)
                if signInResult.isSignedIn {
                    await MainActor.run {
                        isSignedIn = true
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "サインインに失敗しました。追加ステップが必要です。"
                        showErrorAlert = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = translateError(error)
                showErrorAlert = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

