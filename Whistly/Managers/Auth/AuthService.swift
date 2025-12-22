import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

// MARK: - Auth Service
@Observable
class AuthService {
    var currentUser: User?
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    private var auth: Auth? {
        guard FirebaseApp.app() != nil else {
            return nil
        }
        return Auth.auth()
    }
    
    private var db: Firestore? {
        guard FirebaseApp.app() != nil else {
            return nil
        }
        return Firestore.firestore()
    }
    
    init() {
        guard let auth = auth else {
            return
        }
        
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
        currentUser = auth.currentUser
    }
    
    // MARK: - Регистрация
    func signUp(email: String, password: String) async throws {
        guard let auth = auth else {
            throw AuthError.firebaseNotConfigured
        }
        let result = try await auth.createUser(withEmail: email, password: password)
        currentUser = result.user
    }
    
    // MARK: - Вход
    func signIn(email: String, password: String) async throws {
        guard let auth = auth else {
            throw AuthError.firebaseNotConfigured
        }
        let result = try await auth.signIn(withEmail: email, password: password)
        currentUser = result.user
    }
    
    // MARK: - Выход
    func signOut() throws {
        guard let auth = auth else {
            throw AuthError.firebaseNotConfigured
        }
        try auth.signOut()
        currentUser = nil
    }
    
    // MARK: - Сброс пароля
    func resetPassword(email: String) async throws {
        guard let auth = auth else {
            throw AuthError.firebaseNotConfigured
        }
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Сохранение данных в Firestore
    func saveToCloud<T: Codable>(data: T, collection: String) async throws {
        guard let db = db else {
            print("❌ Firebase не настроен")
            throw AuthError.firebaseNotConfigured
        }
        guard let userId = currentUser?.uid else {
            print("❌ Пользователь не авторизован")
            throw AuthError.notAuthenticated
        }
        
        print("🔐 User ID: \(userId)")
        print("📝 Коллекция: \(collection)")
        
        print("🔄 Преобразование данных для Firestore...")
        let firestoreEncoder = Firestore.Encoder()
        let encodedData = try firestoreEncoder.encode(data)
        print("✅ Данные преобразованы для Firestore")
        print("📋 Ключи: \(encodedData.keys.joined(separator: ", "))")
        
        do {
            print("💾 Отправка в Firestore...")
            print("   Путь: \(collection)/\(userId)")
            
            try await db.collection(collection)
                .document(userId)
                .setData(encodedData, merge: true)
            
            print("✅ Данные успешно сохранены в Firestore")
        } catch {
            print("❌ Ошибка при сохранении в Firestore:")
            print("   Тип ошибки: \(type(of: error))")
            print("   Описание: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Код ошибки: \(nsError.code)")
                print("   Домен: \(nsError.domain)")
                print("   UserInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }
    
    // MARK: - Загрузка данных из Firestore
    func loadFromCloud<T: Codable>(collection: String, type: T.Type) async throws -> T? {
        guard let db = db else {
            throw AuthError.firebaseNotConfigured
        }
        guard let userId = currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let document = try await db.collection(collection)
            .document(userId)
            .getDocument()
        
        guard let data = document.data() else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: jsonData)
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case notAuthenticated
    case firebaseNotConfigured
    case serializationError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Пользователь не авторизован"
        case .firebaseNotConfigured:
            return "Firebase не настроен"
        case .serializationError:
            return "Ошибка сериализации данных"
        }
    }
}
