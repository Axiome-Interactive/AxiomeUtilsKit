# AxiomeUtilsKit

Boite a outils iOS (Swift 6) qui regroupe:
- utilitaires reseau (requests, auth, cache, download, mock),
- extensions Foundation / Decodable / Encodable,
- composants et helpers SwiftUI (dont backports iOS 26).

## Compatibilite
- Plateforme: iOS only
- Minimum: iOS 18
- Outil: Swift 6.1

## Installation (SPM)
```swift
dependencies: [
    .package(url: "https://github.com/<org>/AxiomeUtilsKit.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "AxiomeUtilsKit", package: "AxiomeUtilsKit")
        ]
    )
]
```

Puis dans le code:
```swift
import AxiomeUtilsKit
```

## Ce que le module propose
### 1) NetworkUtilsKit
- `RequestProtocol`: decrit une requete HTTP.
- `RequestManager.shared` (actor): execute les requetes et telechargements.
- `Parameters`: payload JSON / form-urlencoded / multipart / body custom.
- `AuthentificationProtocol` + `AuthentificationRefreshableProtocol`: auth async et refresh token.
- `CacheKey` + `NetworkCacheType`: cache local UserDefaults avec expiration.
- `ResponseError` / `RequestError`: erreurs structurees.
- `MockProtocol`: charge des reponses depuis des fichiers locaux.

### 2) UtilsKitCore
- `Decodable.decode(from:)`: decode depuis `Data` ou objet JSON.
- `Encodable.toJson(cleanNilValues:)`: conversion objet -> dictionnaire JSON.
- Extensions `Int` / `Double` pour mesures et arrondis.

### 3) UtilsKitUI
- `UIApplication.getVersion()` / `getBundleVersion()`.
- Helpers `View.if(...)` et `View.ifOptionalObject(...)`.
- Backports SwiftUI via `backport` (glass effects iOS 26, tab bar behavior iOS 26).
- Boutons toolbar prets a l'emploi:
  - `CloseToolbarButton`
  - `ValidateToolbarButton`
  - `DestructiveToolbarButton`

---

## Network: guide d'implementation et d'utilisation

### Architecture execution
1. Tu definis un type `RequestProtocol` par endpoint.
2. Tu appelles:
   - `try await request.response()` pour `(statusCode, data)`,
   - `try await request.response(MyDTO.self)` pour decode direct,
   - ou `try await request.send()` si le body de retour ne t'interesse pas.
3. `RequestManager`:
   - construit le `URLRequest` (URL, query, headers, body),
   - applique timeout/configuration,
   - execute `URLSession.data(for:)`,
   - gere le retry 401 (1 fois) si auth refreshable,
   - trace les logs reseau.

### Comportements importants (precis)
- Merge headers: headers d'auth d'abord, puis headers de requete (la requete ecrase les doublons).
- Merge query params: query de requete prioritaire; les query items auth sont ajoutes seulement si la cle n'existe pas deja.
- Retry 401:
  - si `canRefreshToken == true` (default),
  - et si `authentification` implemente `AuthentificationRefreshableProtocol` (ou tableau contenant des refreshables),
  - alors refresh puis un second appel est tente.
- Annulation:
  - `await request.cancel()` annule toutes les `Task` reseau en cours associees a `request.description`.
  - si la `Task` appelante est annulee (`task.cancel()`), la requete HTTP sous-jacente est aussi annulee automatiquement.
- Cache:
  - `response()` peut servir depuis cache ou fallback cache selon `NetworkCacheType`.

### Definir une requete GET simple
```swift
import Foundation
import AxiomeUtilsKit

struct UserDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct GetUserRequest: RequestProtocol {
    let userID: Int

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/users/\(userID)" }
    var method: RequestMethod { .get }
}

func loadUser(id: Int) async throws -> UserDTO {
    let request = GetUserRequest(userID: id)
    return try await request.response(UserDTO.self)
}
```

### Ajouter headers, query params, timeout, cache policy
```swift
struct SearchUsersRequest: RequestProtocol {
    let query: String

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/users/search" }
    var method: RequestMethod { .get }

    var headers: Headers? {
        ["X-App-Version": "1.0.0"]
    }

    var urlParameters: [String : String]? {
        ["q": query, "limit": "20"]
    }

    var timeoutInterval: TimeInterval? { 15 }
    var cachePolicy: NSURLRequest.CachePolicy { .useProtocolCachePolicy }
}
```

### Body JSON (`Parameters.encodable`)
```swift
struct CreatePostBody: Encodable, Sendable {
    let title: String
    let content: String
}

struct CreatePostRequest: RequestProtocol {
    let body: CreatePostBody

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/posts" }
    var method: RequestMethod { .post }

    var parameters: Parameters? {
        .encodable(body) // Content-Type: application/json
    }
}
```

### Body form-urlencoded (`Parameters.formURLEncoded`)
```swift
struct LoginRequest: RequestProtocol {
    let email: String
    let password: String

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/oauth/token" }
    var method: RequestMethod { .post }

    var parameters: Parameters? {
        .formURLEncoded([
            "grant_type": "password",
            "username": email,
            "password": password
        ])
    }
}
```

### Multipart (`Parameters.formData` + `files`)
```swift
struct UploadAvatarRequest: RequestProtocol {
    let imageData: Data
    let userID: Int

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/users/\(userID)/avatar" }
    var method: RequestMethod { .post }

    var parameters: Parameters? {
        .formData([
            "source": "ios",
            "quality": 90
        ])
    }

    var files: [RequestFile]? {
        [
            RequestFile(
                key: "file",
                name: "avatar.jpg",
                type: "image/jpeg",
                data: imageData
            )
        ]
    }
}
```

### Body custom (`Parameters.other`)
```swift
struct RawDataRequest: RequestProtocol {
    let payload: Data

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/raw" }
    var method: RequestMethod { .post }

    var parameters: Parameters? {
        .other(
            type: (key: "Content-Type", value: "application/octet-stream"),
            data: payload
        )
    }
}
```

## Authentification: implementation precise

### Auth simple (token statique)
```swift
struct StaticBearerAuth: AuthentificationProtocol {
    let token: String

    var headers: Headers {
        get async { ["Authorization": "Bearer \(token)"] }
    }
}
```

Puis dans ta requete:
```swift
struct MeRequest: RequestProtocol {
    let auth: StaticBearerAuth

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/me" }
    var method: RequestMethod { .get }
    var authentification: AuthentificationProtocol? { auth }
}
```

### Auth refreshable (pre-check + retry 401)
```swift
actor RefreshableBearerAuth: AuthentificationRefreshableProtocol {
    private var accessToken: String
    private var expirationDate: Date

    init(token: String, expirationDate: Date) {
        self.accessToken = token
        self.expirationDate = expirationDate
    }

    var headers: Headers {
        get async { ["Authorization": "Bearer \(accessToken)"] }
    }

    nonisolated var urlQueryItems: [URLQueryItem] { [] }

    var isValid: Bool {
        get async { expirationDate > Date() }
    }

    nonisolated func refresh(from request: URLRequest?) async throws {
        // Appel reseau vers endpoint refresh (exemple simplifie).
        let newToken = "new-access-token"
        let newExpiration = Date().addingTimeInterval(3600)
        await update(token: newToken, expirationDate: newExpiration)
    }

    private func update(token: String, expirationDate: Date) {
        self.accessToken = token
        self.expirationDate = expirationDate
    }
}
```

Points clefs:
- `response()` appelle `refreshIfNeeded` avant la requete.
- Si le serveur retourne 401, `RequestManager` tente un refresh puis relance une seule fois.
- Desactive ce comportement via `var canRefreshToken: Bool { false }`.

### Chainer plusieurs strategies d'auth
Tu peux passer un tableau `[any AuthentificationProtocol]` dans `authentification`.
Le module fusionne les headers/query de chaque source.

```swift
struct APIKeyAuth: AuthentificationProtocol {
    let key: String
    var headers: Headers { get async { ["X-API-Key": key] } }
}

let authChain: [any AuthentificationProtocol] = [
    APIKeyAuth(key: "abc"),
    StaticBearerAuth(token: "token")
]
```

## Cache: modes et exemples

### Construire une clef de cache
`CacheKey` est optionnelle a l'init (retourne `nil` si date invalide):
```swift
var cacheKey: CacheKey? {
    CacheKey(
        key: "user-\(userID)",
        type: .returnCacheDataElseLoad,
        minutes: 5
    )
}
```

### Comportement des modes
- `.returnCacheDataElseLoad`
  - si cache valide: retourne cache immediatement,
  - sinon: fait le call reseau.
- `.returnCacheDataDontLoad`
  - si cache valide: retourne cache,
  - sinon: throw `RequestError.emptyCache` (pas d'appel reseau).
- `.returnLoadElseCacheData`
  - tente reseau d'abord,
  - en cas d'erreur, retourne le cache valide si disponible.

Exemple:
```swift
struct CachedUserRequest: RequestProtocol {
    let userID: Int

    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/users/\(userID)" }
    var method: RequestMethod { .get }

    var cacheKey: CacheKey? {
        CacheKey(key: "cached-user-\(userID)", type: .returnLoadElseCacheData, minutes: 10)
    }
}
```

Supprimer le cache de cette requete:
```swift
let request = CachedUserRequest(userID: 42)
request.clearCache()
```

## Erreurs: quoi catcher

### Erreurs reseau/metier
- `ResponseError.network(response:data:)`: code HTTP non 2xx.
- `ResponseError.data`: pas de body alors qu'un decode est demande.
- `ResponseError.decodable(...)`: echec decode.
- `RequestError.url`: URL invalide.
- `RequestError.emptyCache`: cache requis mais absent.

Exemple:
```swift
do {
    let user: UserDTO = try await GetUserRequest(userID: 42).response(UserDTO.self)
    print(user)
} catch let error as ResponseError {
    print("ResponseError code=\(error.code) message=\(error.localizedDescription)")
} catch let error as RequestError {
    print("RequestError: \(error.localizedDescription)")
} catch {
    print("Unexpected: \(error)")
}
```

## Download de fichiers

### 1) Download depuis un `RequestProtocol`
```swift
let destination = FileManager.default.temporaryDirectory.appendingPathComponent("manual.pdf")

let statusCode = try await RequestManager.shared.download(
    destinationURL: destination,
    request: GetUserManualRequest(),
    forceDownload: true,
    progress: { progress in
        // progress: 0.0 -> 1.0 (callback sur MainActor)
        print("progress =", progress)
    }
)

print("download status =", statusCode)
```

### 2) Download direct depuis une URL
```swift
let source = URL(string: "https://example.com/file.zip")!
let destination = FileManager.default.temporaryDirectory.appendingPathComponent("file.zip")

_ = try await RequestManager.shared.download(
    sourceURL: source,
    destinationURL: destination,
    timeout: 30,
    forceDownload: false
)
```

Comportement `forceDownload`:
- `false` + fichier deja present => retourne succes `200` sans re-download.
- `true` + fichier deja present => supprime puis retente download.
- si la `Task` appelante est annulee, le `URLSessionDownloadTask` sous-jacent est annule aussi.

## Annuler une requete en cours
```swift
let request = GetUserRequest(userID: 42)
let task = Task {
    try await request.response(UserDTO.self)
}

// Plus tard:
await request.cancel()
_ = try? await task.value
```

Tu peux aussi annuler directement la task appelante:
```swift
let task = Task {
    try await GetUserRequest(userID: 42).response(UserDTO.self)
}

// Plus tard:
task.cancel() // annule la requete HTTP en cours
_ = try? await task.value
```

## Mocking local (tests / previews)
`MockProtocol` permet de lire un JSON local au lieu d'appeler le reseau.

```swift
struct MockedUserRequest: MockProtocol {
    var scheme: String { "https" }
    var host: String { "api.example.com" }
    var path: String { "/v1/users/42" }
    var method: RequestMethod { .get }

    var mockFileURL: URL? {
        Bundle.main.url(forResource: "user_42", withExtension: "json")
    }
}

let dto: UserDTO = try await MockedUserRequest().mock(UserDTO.self)
```

---

## UtilsKitCore: exemples rapides

### Decodable decode helper
```swift
let dto: UserDTO = try UserDTO.decode(from: data)
```

### Encodable -> JSON dictionnaire
```swift
struct Payload: Encodable { let name: String; let age: Int? }
let json = Payload(name: "Ana", age: nil).toJson(cleanNilValues: true)
```

### Int / Double helpers
```swift
let distance = 1200.0.asFormattedScale      // "1.20km"
let speed = 50.kilometersPerHour            // Measurement<UnitSpeed>
let rounded = 37.roundNearMultiple(multiple: 10) // 40
```

## UtilsKitUI: exemples rapides

### Conditionner des modifiers
```swift
Text("Hello")
    .if(isPremium) { view in
        view.bold()
    }
```

### Backport glass effect
```swift
Text("Card")
    .padding()
    .backport.glassEffect(.regular)
```

### Toolbar buttons
```swift
ToolbarItem(placement: .topBarTrailing) {
    ValidateToolbarButton {
        // confirm action
    }
}
```

## Conseils d'implementation
- Cree un type `RequestProtocol` par endpoint (lisibilite + testabilite).
- Utilise des DTO `Decodable & Sendable` pour Swift 6 strict.
- Centralise auth dans des types `AuthentificationProtocol` dedies.
- Active cache uniquement sur endpoints idempotents (GET).
- Pour les uploads/downloads, trace et monitore les erreurs `ResponseError.network`.
