import Foundation
import Netify  // Netify 라이브러리를 임포트합니다.
import OSLog   // 상세 오류 로깅을 위해 추가

// MARK: - Models
// API 응답을 디코딩하는 데 사용될 데이터 모델 정의

struct UserList: Codable {
    let users: [User]
}

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

struct Post: Codable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

struct Comment: Codable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

// 예시: 날짜 형식이 다른 응답을 위한 모델
struct PostWithCustomDate: Codable {
    let id: Int
    let title: String
    let publishedAt: Date // 서버가 ISO8601 형식으로 날짜를 준다고 가정
}

// Netify는 EmptyResponse를 내장하고 있으므로 별도 정의 필요 없음

// MARK: - Request Definitions

extension User {
    struct Request: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = User

        let path: String
        let method: HTTPMethod = .get

        init(userId: Int) {
            self.path = "/users/\(userId)"
        }
    }
}

// 가장 기본적인 GET 요청 예시 (모든 게시글 가져오기)
struct GetAllPostsRequest: NetifyRequest {
    typealias ReturnType = [Post] // 여러 Post 객체를 배열로 기대
    let path = "/posts"
    // method는 기본값이 .get이므로 생략 가능
    // queryParams, body 등 다른 속성도 필요 없으면 생략
    var requiresAuthentication: Bool = false // 이 API는 인증 불필요
}

// Post 모델 관련 요청 정의
// MARK: - Post Requests
extension Post {
    struct GetUserPostsRequest: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = [Post]

        let path: String  // 요청 경로 (예: /users/1/posts)
        let method: HTTPMethod = .get

        init(userId: Int) {
            self.path = "/users/\(userId)/posts"
        }
    }

    struct CreateRequest: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = Post

        let path = "/posts" // 요청 경로
        let method: HTTPMethod = .post
        // NetifyRequest의 body는 Any? 타입이므로, Encodable 객체나 Dictionary를 직접 할당합니다.
        // JSON으로 보내려면 Dictionary<String, Any> 또는 아래 Encodable 예제처럼 구조체를 사용합니다.
        let body: [String: Any]?  // Netify의 body 타입에 맞게 수정 (Any? 또는 Encodable)

        init(title: String, body: String, userId: Int) {
            self.body = [
                "title": title,
                "body": body,
                "userId": userId,
            ]
        }
    }

    // 게시글 생성을 위한 Encodable 모델
    struct CreatePostBody: Encodable {
        let title: String
        let body: String
        let userId: Int
    }

    // Encodable 객체를 본문으로 사용하는 POST 요청
    struct CreateWithEncodableRequest: NetifyRequest {
        typealias ReturnType = Post // 생성된 Post 객체를 기대
        let path = "/posts"
        let method: HTTPMethod = .post
        let body: Encodable? // body 타입을 Encodable? 로 명시 (CreatePostBody 인스턴스 할당)

        init(postData: CreatePostBody) { self.body = postData }
    }

    // 게시글 업데이트 요청 정의
    struct UpdateRequest: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = Post  // 업데이트된 게시글 반환

        let path: String  // 경로에 업데이트할 게시글 ID 포함 (예: /posts/1)
        let method: HTTPMethod = .put
        let body: [String: Any]?  // 업데이트할 내용

        init(postId: Int, title: String, body: String, userId: Int) {
            self.path = "/posts/\(postId)"
            self.body = [
                "id": postId,  // API에 따라 ID를 본문에 포함할 수 있음
                "title": title,
                "body": body,
                "userId": userId,
            ]
        }
    }

    // 게시글 삭제 요청 정의
    struct DeleteRequest: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = EmptyResponse  // 삭제 성공 시 내용 없는 응답 기대

        let path: String  // 경로에 삭제할 게시글 ID 포함 (예: /posts/1)
        let method: HTTPMethod = .delete
        // DELETE 요청은 보통 body가 없음

        init(postId: Int) {
            self.path = "/posts/\(postId)"
        }
    }
}

// Comment 모델 관련 요청 정의
// MARK: - Comment Requests
extension Comment {
    struct GetPostCommentsRequest: NetifyRequest {  // DecRequest -> NetifyRequest
        typealias ReturnType = [Comment]  // 댓글 배열 반환

        let path: String = "/comments"  // 댓글 기본 경로
        let method: HTTPMethod = .get
        let queryParams: QueryParameters?  // NetifyRequest의 queryParams 사용

        init(postId: Int) {
            // postId를 문자열로 변환하여 쿼리 파라미터 설정
            self.queryParams = ["postId": String(postId)]
        }
    }
}

// MARK: - Advanced Request Definitions

// 예시: 커스텀 디코더를 사용하는 요청
extension PostWithCustomDate {
    struct GetPostWithDateRequest: NetifyRequest {
        typealias ReturnType = PostWithCustomDate

        let path: String
        let method: HTTPMethod = .get
        var decoder: JSONDecoder? // 커스텀 디코더 지정

        init(postId: Int) {
            self.path = "/posts/\(postId)" // 실제 API는 이 형식을 지원하지 않을 수 있음 (예시용)
            // ISO8601 날짜 형식을 처리하는 커스텀 디코더 설정
            let customDecoder = JSONDecoder()
            customDecoder.dateDecodingStrategy = .iso8601
            self.decoder = customDecoder
        }
    }
}

// 예시: 원시 Data를 반환받는 요청 (이미지 다운로드 등)
struct GetRawDataRequest: NetifyRequest {
    typealias ReturnType = Data // 반환 타입을 Data로 지정

    let path: String // 예: 이미지 파일 경로
    let method: HTTPMethod = .get
    var requiresAuthentication: Bool = false // 예시: 인증 불필요

    init(imagePath: String) {
        // 중요: 실제 API 경로로 변경해야 함
        // jsonplaceholder는 이미지 경로를 제공하지 않으므로, 다른 더미 API나 실제 API 사용 필요
        self.path = imagePath // 예: "/images/logo.png"
    }
}

// 예시: 요청별 타임아웃을 설정하는 GET 요청
struct GetUserWithCustomTimeoutRequest: NetifyRequest {
    typealias ReturnType = User
    let path: String
    let method: HTTPMethod = .get
    var timeoutInterval: TimeInterval? = 5.0 // 5초 타임아웃 설정 (기본값보다 짧게)
    var requiresAuthentication: Bool = false

    init(userId: Int) {
        self.path = "/users/\(userId)"
    }
}

// 예시: 5xx 오류 재시도 테스트용 요청 (httpbin.org 사용)
struct Get503ErrorRequest: NetifyRequest {
    typealias ReturnType = EmptyResponse // 응답 본문은 중요하지 않음
    let path = "/status/503" // 503 Service Unavailable 오류를 반환하는 경로
    let method: HTTPMethod = .get
    var requiresAuthentication: Bool = false
}

// 예시: 멀티파트 업로드 요청 구조
struct UploadImageRequest: NetifyRequest {
    typealias ReturnType = EmptyResponse // 업로드 성공 시 빈 응답 기대
    let path: String = "/upload" // 실제 업로드 경로로 변경 필요
    let method: HTTPMethod = .post
    var contentType: HTTPContentType { .multipart } // ContentType을 multipart로 명시
    var multipartData: [MultipartData]? // 실제 파일 데이터
    var requiresAuthentication: Bool = true // 보통 업로드는 인증 필요

    init(imageData: Data, fileName: String, mimeType: String) {
        self.multipartData = [
            MultipartData(name: "file", fileData: imageData, fileName: fileName, mimeType: mimeType)
            // 필요시 다른 폼 필드 추가 가능
            // MultipartData(name: "userId", fileData: "123".data(using: .utf8)!, fileName: "", mimeType: "text/plain")
        ]
    }
}

// MARK: - Basic Usage Function

/// Netify의 기본적인 GET, POST, PUT, DELETE 흐름을 보여주는 예제 함수입니다.
@available(iOS 15, macOS 12, *)
func fetchData() async {
    print("--- Starting Basic Fetch Sequence ---")
    // 1. 기본 Netify 클라이언트 설정 생성
    let configuration = NetifyConfiguration(
        baseURL: "https://jsonplaceholder.typicode.com",
        logLevel: .debug  // 개발 중에는 debug 레벨로 설정하여 상세 로그 확인
            // 필요시 다른 설정 추가 (타임아웃, 기본 헤더 등)
    )
    // 2. 기본 Netify 클라이언트 인스턴스 생성
    let netifyClient = NetifyClient(configuration: configuration)
    print("🚀 Netify API 요청 시퀀스를 시작합니다...")

    do {
        // 2. 가장 기본적인 GET 요청 (모든 게시글 가져오기)
        print("\n[GET] 모든 게시글 목록 가져오는 중...")
        let allPosts = try await netifyClient.send(GetAllPostsRequest())
        print("✅ 총 \(allPosts.count)개의 게시글 가져옴.")
        if let firstPost = allPosts.first {
            print("   - 첫 번째 게시글 제목: \(firstPost.title)")
        }


        // 3. 특정 사용자 정보 가져오기 (ID: 1)
        // --- GET User ---
        print("\n[GET] 사용자 ID 1 정보 가져오는 중...")
        let user = try await netifyClient.send(User.Request(userId: 1))
        print("✅ 사용자 정보 가져옴: \(user.name) (\(user.email))")

        // 4. 해당 사용자의 게시글 목록 가져오기
        print("\n[GET] 사용자 ID \(user.id)의 게시글 목록 가져오는 중...")
        let posts = try await netifyClient.send(Post.GetUserPostsRequest(userId: user.id))
        print("✅ \(posts.count)개의 게시글 가져옴.")

        // 5. 첫 번째 게시글의 댓글 목록 가져오기 (게시글이 있을 경우)
        // --- GET Comments (using query parameter) ---
        if let firstPost = posts.first {
            print("\n[GET] 게시글 ID \(firstPost.id)의 댓글 목록 가져오는 중...")
            let comments = try await netifyClient.send(
                Comment.GetPostCommentsRequest(postId: firstPost.id))
            print("✅ 게시글 ID \(firstPost.id)에 대한 댓글 \(comments.count)개 가져옴.")
            if let firstComment = comments.first {
                print("   - 첫 번째 댓글 내용: \(firstComment.body.prefix(50))...")
            }
        } else {
            print("   - 사용자 ID \(user.id)는 작성한 게시글이 없습니다.")
        }

        // 6. 새 게시글 생성하기 (Dictionary 사용)
        // --- POST Post ---
        print("\n[POST] 새 게시글 생성 중 (Dictionary 사용)...")
        let newPost = try await netifyClient.send(
            Post.CreateRequest(title: "New Post", body: "This is a new post", userId: user.id)
        )
        // jsonplaceholder는 생성 시 ID를 101로 반환하는 경향이 있음
        print("✅ 새 게시글 생성됨: \(newPost.title) (ID: \(newPost.id))")

        // 7. 새 게시글 생성하기 (Encodable 객체 사용)
        // --- POST Post with Encodable ---
        print("\n[POST] 새 게시글 생성 중 (Encodable 객체 사용)...")
        let postData = Post.CreatePostBody(title: "Encodable Post", body: "Using Encodable struct", userId: user.id)
        let createdPostEncodable = try await netifyClient.send(Post.CreateWithEncodableRequest(postData: postData))
        print("✅ Encodable 본문으로 게시글 생성됨: \(createdPostEncodable.title) (ID: \(createdPostEncodable.id))")

        print("✅ 새 게시글 생성됨: \(newPost.title) (ID: \(newPost.id))")

        // 7. 생성된 게시글 업데이트하기
        // --- PUT Post ---
        print("\n[PUT] 게시글 ID \(newPost.id) 업데이트 중...")
        let updatedPost = try await netifyClient.send(
            Post.UpdateRequest(
                postId: newPost.id, title: "Updated Title", body: "Content updated.",
                userId: user.id)
        )
        print("✅ 게시글 업데이트됨: \(updatedPost.title) (ID: \(updatedPost.id))")
        print("   - 업데이트된 내용: \(updatedPost.body)")

        // 8. 게시글 삭제하기
        // --- DELETE Post ---
        print("\n[DELETE] 게시글 ID \(updatedPost.id) 삭제 중...")
        // DeleteRequest의 ReturnType이 EmptyResponse이므로 반환값은 사용하지 않음
        _ = try await netifyClient.send(Post.DeleteRequest(postId: updatedPost.id))
        print("✅ 게시글 ID \(updatedPost.id) 삭제됨.")

        print("\n🎉 모든 Netify API 요청이 성공적으로 완료되었습니다!")

    } catch {
        // 기본 예제에서는 간단히 오류 출력
        handleNetifyError(error, context: "Basic Fetch Sequence")
    }
    print("--- Finished Basic Fetch Sequence ---")
}

// MARK: - Advanced Usage Function

/// Netify의 고급 기능(인증, 커스텀 디코더, 재시도, 타임아웃, 취소, 멀티파트 등)을 보여주는 예제 함수입니다.
@available(iOS 15, macOS 12, *)
func fetchAdvancedData() async {
    print("\n--- Starting Advanced Fetch Sequence ---")

    // --- Example: Client with Authentication (Simulated) ---
    // 실제 사용 시에는 토큰을 안전하게 관리하고 유효한 핸들러를 제공해야 합니다.
    let dummyTokenProvider = BearerTokenAuthenticationProvider(
        accessToken: "DUMMY_ACCESS_TOKEN",
        refreshToken: "DUMMY_REFRESH_TOKEN",
        refreshHandler: { _ in
            print("⚠️ Dummy Refresh Handler Called - Should not happen in this example")
            // 실제로는 여기서 서버에 토큰 갱신 요청을 보내야 함
            throw NetworkRequestError.unauthorized(data: nil) // 갱신 실패 시나리오
        }
    )

    let authConfig = NetifyConfiguration(
        baseURL: "https://jsonplaceholder.typicode.com", // 실제 인증 API URL로 변경 필요
        logLevel: .debug,
        authenticationProvider: dummyTokenProvider
    )
    let authClient = NetifyClient(configuration: authConfig)

    print("\n[AUTH GET] 인증이 필요한 리소스 요청 시뮬레이션 (ID: 1)...")
    do {
        // User.Request는 기본적으로 requiresAuthentication=true 입니다.
        // 요청 시 AuthenticationProvider가 자동으로 헤더를 추가합니다.
        let authenticatedUser = try await authClient.send(User.Request(userId: 1))
        print("✅ (Simulated) Authenticated User Fetched: \(authenticatedUser.name)")
        // 참고: jsonplaceholder는 실제 인증을 요구하지 않으므로, 이 요청은 성공할 것입니다.
        // 실제 인증 API에서는 401 오류 시 토큰 갱신 로직이 트리거될 수 있습니다.
    } catch {
        handleNetifyError(error, context: "Authenticated Request")
    }

    // --- Example: Custom Decoder ---
    let basicClient = NetifyClient(configuration: .init(baseURL: "https://jsonplaceholder.typicode.com", logLevel: .info))
    print("\n[GET with Custom Decoder] 커스텀 디코더 사용 요청 (Post ID: 1)...")
    do {
        // 실제 jsonplaceholder 응답에는 'publishedAt' 필드가 없으므로 디코딩 에러 발생 예상
        let _ = try await basicClient.send(PostWithCustomDate.GetPostWithDateRequest(postId: 1))
        print("✅ Post with custom date fetched (Unexpected Success)")
    } catch {
        // 여기서 decodingError가 발생하는 것이 정상적인 시나리오입니다.
        handleNetifyError(error, context: "Custom Decoder Request")
    }

    // --- Example: Fetching Raw Data ---
    // 중요: jsonplaceholder는 이미지 URL을 제공하지 않습니다.
    // 다른 이미지 제공 API URL (예: https://picsum.photos) 또는 실제 URL로 변경해야 합니다.
    let imageClientConfig = NetifyConfiguration(baseURL: "https://via.placeholder.com", logLevel: .info) // 예시 이미지 URL
    let imageClient = NetifyClient(configuration: imageClientConfig)
    print("\n[GET Raw Data] 원시 데이터(이미지) 요청...")
    do {
        let imageData = try await imageClient.send(GetRawDataRequest(imagePath: "/150")) // 예시 경로
        print("✅ Raw data fetched: \(imageData.count) bytes")
        // 실제 앱에서는 이 데이터를 UIImage 등으로 변환하여 사용
    } catch {
        handleNetifyError(error, context: "Raw Data Request")
    }

    print("\n[POST Multipart] 멀티파트 요청 시뮬레이션 (실제 전송은 실패 예상)...")
    do {
        let dummyImageData = "dummy image data".data(using: .utf8)!
        let uploadRequest = UploadImageRequest(imageData: dummyImageData, fileName: "test.jpg", mimeType: "image/jpeg")
        // 실제로는 authClient나 적절한 클라이언트를 사용해야 함
        _ = try await basicClient.send(uploadRequest) // jsonplaceholder는 404 반환 예상
        print("✅ (Simulated) Multipart request sent (Unexpected Success)")
    } catch {
        // 404 Not Found 또는 다른 오류가 정상입니다.
        handleNetifyError(error, context: "Multipart Request Simulation")
    }

    // --- Example: Custom Timeout ---
    let timeoutClientConfig = NetifyConfiguration(baseURL: "https://jsonplaceholder.typicode.com", logLevel: .debug, timeoutInterval: 30.0) // 기본 30초
    let timeoutClient = NetifyClient(configuration: timeoutClientConfig)
    print("\n[GET with Custom Timeout] 사용자 ID 1 정보 가져오는 중 (5초 타임아웃)...")
    do {
        // 네트워크 상태가 매우 느릴 경우, 이 요청은 기본 타임아웃(30초) 전에 5초 타임아웃으로 실패할 수 있음
        let user = try await timeoutClient.send(GetUserWithCustomTimeoutRequest(userId: 1))
        print("✅ 사용자 정보 가져옴 (커스텀 타임아웃 내): \(user.name)")
    } catch let error as NetworkRequestError where error == .timedOut {
        print("🕒 요청 시간 초과 (5초). 예상된 동작일 수 있습니다.")
        handleNetifyError(error, context: "Custom Timeout Request")
    } catch {
        handleNetifyError(error, context: "Custom Timeout Request")
    }

    // --- Example: Retry Mechanism ---
    // 재시도 횟수를 3으로 설정 (총 1번의 원본 요청 + 3번의 재시도 = 최대 4번 시도)
    // 실제 테스트를 위해서는 5xx 오류나 타임아웃을 유발하는 API 엔드포인트 필요
    let retryClientConfig = NetifyConfiguration(
        baseURL: "https://httpbin.org", // 5xx 오류 테스트 가능한 API 사용 (예시)
        logLevel: .debug,
        maxRetryCount: 3 // 재시도 3회 설정
    )
    let retryClient = NetifyClient(configuration: retryClientConfig)
    print("\n[GET with Retry] 503 오류를 유발하여 재시도 테스트 중...")
    do {
        // 이 요청은 503 오류를 반환하고, NetifyClient는 설정된 횟수만큼 재시도함
        _ = try await retryClient.send(Get503ErrorRequest())
        print("✅ 요청 성공 (재시도 후 성공? - httpbin은 즉시 503 반환)")
    } catch let error as NetworkRequestError where error.isRetryable {
        print("🔄 재시도 가능한 오류 발생 후 최종 실패: \(error.localizedDescription)")
        handleNetifyError(error, context: "Retry Request")
    } catch {
        handleNetifyError(error, context: "Retry Request")
    }

    // --- Example: Request Cancellation ---
    print("\n[GET with Cancellation] 사용자 정보 요청 시작 후 즉시 취소 시도...")
    let cancelClient = NetifyClient(configuration: .init(baseURL: "https://jsonplaceholder.typicode.com", logLevel: .debug))
    // Task 생성
    let task = Task {
        do {
            print("   - Task: 사용자 ID 1 정보 요청 시작...")
            // 일부러 지연이 긴 API를 호출하거나, 요청 직후 취소
            let user = try await cancelClient.send(User.Request(userId: 1))
            // 취소가 성공하면 이 라인은 실행되지 않음
            print("   - Task: 사용자 정보 수신 완료 (취소 실패 시): \(user.name)")
        } catch is CancellationError {
            // Task.checkCancellation() 또는 네트워크 작업 중 취소 감지 시 발생
            print("   - Task: 요청이 성공적으로 취소되었습니다 (Swift Concurrency).")
        } catch let error as NetworkRequestError where error == .cancelled {
            // Netify 내부에서 취소를 감지하고 .cancelled 오류를 던진 경우
             print("   - Task: Netify가 요청 취소를 감지했습니다.")
             handleNetifyError(error, context: "Cancellation Test")
        } catch {
            // 기타 오류
            print("   - Task: 요청 중 예상치 못한 오류 발생.")
            handleNetifyError(error, context: "Cancellation Test")
        }
    }
    // Task 시작 후 아주 짧은 시간 뒤에 취소
    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms 대기 (네트워크 요청 시작 시간 확보)
    print("   - Main: Task 취소 요청...")
    task.cancel()
    await task.value // Task 완료 대기 (선택 사항)

    print("\n--- Finished Advanced Fetch Sequence ---")
}

// MARK: - Error Handling Helper
/// Netify 요청 중 발생하는 오류를 처리하고 로그를 출력하는 헬퍼 함수입니다.
@available(iOS 15, macOS 12, *)
func handleNetifyError(_ error: Error, context: String) {
    print("\n❌ Netify 요청 중 오류 발생 (Context: \(context)):")

    guard let netifyError = error as? NetworkRequestError else {
        // NetifyError가 아닌 다른 오류 (예: Task 취소 등)
        print("   - Non-Netify Error: \(error.localizedDescription)")
        print("   - Error Type: \(type(of: error))")
        return
    }

    // NetifyError의 상세 정보 출력
    print("   - Error Type: \(netifyError)") // enum case 이름
    print("   - Description: \(netifyError.localizedDescription)") // 사용자 친화적 설명

    // Debug 레벨에서는 더 상세한 정보 제공
    #if DEBUG
    print("   - Debug Info: \(netifyError.debugDescription)")
    #endif

    // 특정 오류 유형에 따른 추가 처리 예시
    switch netifyError {
    case .decodingError(let underlyingError, let data):
        print("   - Decoding Failed: \(underlyingError)")
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            print("   - Received Data (String): \(dataString.prefix(200))...")
        }
    case .unauthorized:
        print("   - Action: 인증 실패. 로그인 화면으로 이동하거나 토큰 갱신 로직 확인 필요.")
    case .noInternetConnection:
        print("   - Action: 인터넷 연결 상태 확인 메시지 표시.")
    case .timedOut:
        print("   - Action: 요청 시간 초과. 서버 상태 확인 또는 타임아웃 시간 조정 고려.")
    default:
        break // 다른 케이스는 기본 정보만 출력
    }
}

// MARK: - Application Entry Point

@main
struct NetifyExamplesApp {
    @available(iOS 15, macOS 12, *)
    static func main() async {
        print("===== Netify Example App Started =====")
        
        // 1. 기본적인 API 호출 흐름 예제 실행
        await fetchData()
        
        // 2. 인증, 재시도, 커스텀 설정 등 고급 기능 예제 실행
        await fetchAdvancedData()
        
        print("\n===== Netify Example App Finished =====")
        // 실제 앱에서는 여기서 RunLoop 등을 실행해야 할 수 있지만,
        // 예제 실행 목적이므로 비동기 작업 완료 후 종료됩니다.
    }
}

// --- 예제 실행 방법 ---
// SwiftUI View의 .onAppear 등 적절한 위치에서 Task를 사용하여 호출
//
// struct ContentView: View {
//     var body: some View {
//         Text("Netify Example")
//             .onAppear {
//                 Task {
//                     await fetchData()
//                 }
//             }
//     }
// }
//
// // 또는 앱의 다른 초기화 지점에서 호출
// Task {
//     await fetchData()
// }
