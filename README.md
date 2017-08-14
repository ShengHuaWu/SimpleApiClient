## Simple iOS API client with Alamofire
Most of the iOS applications have to communicate with their backend servers, in order to manipulate their data. My purpose is to implement a simple API client example with [_Alamofire_](https://github.com/Alamofire/Alamofire) , which is a very famous Swift third party library. In this article, I will create one endpoint with two different HTTP methods, and show how to take the advantage of Alamofire to send HTTP requests. I will demonstrate how to write unit tests for our API client in the end of this article as well.

This article is designed for developers who are familiar with iOS networking layer and Alamofire. Furthermore, please note that this article adopts Swift 2.2, Xcode 7.3 and Alamofire 3.4.1.

### Implementation
#### Endpoint
Let's get started with our endpoint, and it's appropriate to present our endpoint with Swift enum.
```
enum Endpoint {
    case GetUserInfo(userId: String)
    case UpdateUserInfo(userId: String)

    // MARK: - Public Properties
    var method: Alamofire.Method {
        switch self {
        case .GetUserInfo:
            return .GET
        case .UpdateUserInfo:
            return .PUT
        }
    }

    var url: NSURL {
        let baseUrl = NSURL.getBaseUrl()
        switch self {
        case .GetUserInfo(let userId):
            return baseUrl.URLByAppendingPathComponent("user/\(userId)")
        case .UpdateUserInfo(let userId):
            return baseUrl.URLByAppendingPathComponent("user/\(userId)")
        }
    }
}
```
We create one endpoint with two different HTTP methods here. One is used to get the user information from the backend server, and the other is used to update the user information.

#### User Model
Our API should return the user information as the result. In order to parse the response JSON data, we create a User model type as following. (I used my own JSONParser component in this project, but that is removed. Therefore, please choose [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for Swift 3, or _Codable_ protocol for Swift 4.)

```
struct User {
    let userId: String
    var name: String
    var email: String
    var description: String?
}

extension User {
    init(json: JSON) {
        userId = json["userId"].stringValue
        name = json["name"].stringValue
        email = json["email"].stringValue
        description = json["description"].string
    }

    func toParameters() -> [String : AnyObject] {
        var parameters = ["userId" : userId, "name" : name, "email" : email]
        if let description = description {
            parameters["description"] = description
        }

        return parameters
    }
}
```

#### Extensions
Before writing our API class, we should customize Alamofire _Manager_ and _Request_ to fit our usage.
```
extension Manager {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil) -> Request {
        // Insert your common headers here, for example, authorization token or accept.
        var commonHeaders = ["Accept" : "application/json"]
        if let headers = headers {
            commonHeaders += headers
        }

        return request(endpoint.method, endpoint.url, parameters: parameters, headers: commonHeaders)
    }
}
```
We write an extension of Alamofire Manager at first, and it contains a method which uses our endpoint to generate an Alamofire Request.

```
extension Request {
    static func apiResponseSerializer() -> ResponseSerializer<JSON, NSError> {
        return ResponseSerializer { _, _, data, error in
            if let error = error {
                return .Failure(error)
            }

            guard let validData = data else {
                let reason = "Data could not be serialized. Input data was nil."
                return .Failure(NSError(domain: "com.shenghuawu.simpleapiclient", code: 1001, userInfo: [NSLocalizedDescriptionKey : reason]))
            }

            do {
                let json = try JSON(data: validData)
                // TODO: Should consider HTTP response as well.
                return sanitizeError(json)
            } catch let error as NSError {
                return .Failure(error)
            }
        }
    }

    static func sanitizeError(json: JSON) -> Result<JSON, NSError> {
        if json["error"].object == nil {
            return .Success(json)
        }

        let code = json["error"]["code"].intValue
        let message = json["error"]["message"].stringValue
        let error = NSError(domain: "com.shenghuawu.simpleapiclient", code: code, userInfo: [NSLocalizedDescriptionKey : message])
        return .Failure(error)
    }

    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        return response(responseSerializer: Request.apiResponseSerializer(), completionHandler: completionHandler)
    }
}
```
What we do here is to create a custom response serializer of Alamofire Request, and sanitize error with the server response JSON data.

#### API class
There is still one thing to do before writing our API class, and we should create a generic Swift enum to represent the result of our API.
```
enum ApiResult<Value> {
    case Success(value: Value)
    case Failure(error: NSError)

    init(_ f: () throws -> Value) {
        do {
            let value = try f()
            self = .Success(value: value)
        } catch let error as NSError {
            self = .Failure(error: error)
        }
    }

    func unwrap() throws -> Value {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}
```
Finally, let's write our API class.
```
final class Api {
    // MARK: - Private Properties
    private let manager: Manager

    // MARK: - Designated Initializer
    init(manager: Manager = Manager.sharedInstance) {
        self.manager = manager
    }

    // MARK: - Public Methods
    func getUserInfo(userId: String, completion: ApiResult<User> -> Void) {
        manager.apiRequest(.GetUserInfo(userId: userId)).apiResponse { response in
            switch response.result {
            case .Success(let json):
                let user = User(json: json["data"])
                completion(ApiResult{ return user })
            case .Failure(let error):
                completion(ApiResult{ throw error })
            }
        }
    }

    func updateUserInfo(user: User, completion: ApiResult<User> -> Void) {
        manager.apiRequest(.UpdateUserInfo(userId: user.userId), parameters: user.toParameters()).apiResponse { response in
            switch response.result {
            case .Success(let json):
                let user = User(json: json["data"])
                completion(ApiResult{ return user })
            case .Failure(let error):
                completion(ApiResult{ throw error })
            }
        }
    }
}
```

### Unit Testing
Although I'm not familiar with TDD, it's still important to write unit tests for our API class. However, we need to finish several things at first.

#### Protocols
Perhaps the simplest way to test our API class is by letting it access the network. The request could hit an endpoint on the server. Then we can assure that the response is parsed into valid User model objects. While easy to set up, this approach has a few downsides.
First, the tests will take much longer to run. If we have a poor network connection they will take even longer. Asynchronous tests are also not reliable. The more tests we have the higher the likelihood one or more will fail randomly. Since Swift is protocol-oriented programming, I would like to use protocols to make Alamofire Manager and Request testable. Let's create two protocols as following.
```
protocol ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol
}

protocol ApiRequestProtocol {
    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self
}
```
Then rewrite the previous extensions of _Manage_ and _Request_, in order to conform these protocols respectively.
```
extension Manager: ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil) -> ApiRequestProtocol {
        // Insert your common headers here, for example, authorization token or accept.
        var commonHeaders = ["Accept" : "application/json"]
        if let headers = headers {
            commonHeaders += headers
        }

        return request(endpoint.method, endpoint.url, parameters: parameters, headers: commonHeaders)
    }
}

extension Request: ApiRequestProtocol {
    static func apiResponseSerializer() -> ResponseSerializer<JSON, NSError> {
        return ResponseSerializer { _, _, data, error in
            if let error = error {
                return .Failure(error)
            }

            guard let validData = data else {
                let reason = "Data could not be serialized. Input data was nil."
                return .Failure(NSError(domain: "com.shenghuawu.simpleapiclient", code: 1001, userInfo: [NSLocalizedDescriptionKey : reason]))
            }

            do {
                let json = try JSON(data: validData)
                // TODO: Should consider HTTP response as well.
                return sanitizeError(json)
            } catch let error as NSError {
                return .Failure(error)
            }
        }
    }

    static func sanitizeError(json: JSON) -> Result<JSON, NSError> {
        if json["error"].object == nil {
            return .Success(json)
        }

        let code = json["error"]["code"].intValue
        let message = json["error"]["message"].stringValue
        let error = NSError(domain: "com.shenghuawu.simpleapiclient", code: code, userInfo: [NSLocalizedDescriptionKey : message])
        return .Failure(error)
    }

    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        return response(responseSerializer: Request.apiResponseSerializer(), completionHandler: completionHandler)
    }
}
```
For our convenience, add the following extension for _ApiManagerProtocol_.
```
extension ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint) -> ApiRequestProtocol {
        return apiRequest(endpoint, parameters: nil, headers: nil)
    }

    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?) -> ApiRequestProtocol {
        return apiRequest(endpoint, parameters: parameters, headers: nil)
    }
}
```
Furthermore, change the type of our API class's property to be _ApiManagerProtocol_.
```
final class Api {
    // MARK: - Private Properties
    private let manager: ApiManagerProtocol

    // MARK: - Designated Initializer
    init(manager: ApiManagerProtocol = Manager.sharedInstance) {
        self.manager = manager
    }
    ...
}
```

#### Mock Objects
Now we're able to create lightweight mock objects with these protocols in our test target.
```
class MockManager: ApiManagerProtocol {
    var expectedRequest: MockRequest?

    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol {
        guard let request = expectedRequest else {
            fatalError("Request is empty.")
        }
        return request
    }
}

class MockRequest: ApiRequestProtocol {
    var expectedData: [String : AnyObject]?
    var expectedError: NSError?

    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        if let data = expectedData {
            let result: Result<JSON, NSError> = .Success(JSON(object: data))
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } else if let error = expectedError {
            let result: Result<JSON, NSError> = .Failure(error)
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } else {
            fatalError("Both data and error are empty.")
        }

        return self
    }
}
```

#### Writing Tests
Finally, we can write some tests for our API class.
```
class ApiTests: XCTestCase {
    // MARK: - Private Properties
    private var api: Api!
    private var mockManager: MockManager!

    // MARK: - Override Methods
    override func setUp() {
        super.setUp()

        mockManager = MockManager()
        mockManager.expectedRequest = MockRequest()
        api = Api(manager: mockManager)
    }

    override func tearDown() {
        super.tearDown()

        api = nil
        mockManager = nil
    }

    // MARK: - Enabled Tests
    func testGetUserInfoWithData() {
        let expectedUser = User.userForTesting()
        let expectedData = ["data" : expectedUser.toParameters()]
        mockManager.expectedRequest?.expectedData = expectedData

        api.getUserInfo(expectedUser.userId) { result in
            do {
                let user = try result.unwrap()

                XCTAssertEqual(user.userId, expectedUser.userId)
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.email, expectedUser.email)
                XCTAssertEqual(user.description, expectedUser.description)
            } catch {
                XCTAssert(false)
            }
        }
    }

    func testGetUserInfoWithError() {
        let expectedError = NSError.errorForTesting()
        mockManager.expectedRequest?.expectedError = expectedError

        api.getUserInfo("") { result in
            do {
                _  = try result.unwrap()

                XCTAssert(false)
            } catch let error as NSError {
                XCTAssertEqual(error, expectedError)
            }
        }
    }

    func testUpdateUserInfoWithData() {
        let expectedUser = User.userForTesting()
        let expectedData = ["data" : expectedUser.toParameters()]
        mockManager.expectedRequest?.expectedData = expectedData

        api.updateUserInfo(expectedUser) { result in
            do {
                let user = try result.unwrap()

                XCTAssertEqual(user.userId, expectedUser.userId)
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.email, expectedUser.email)
                XCTAssertEqual(user.description, expectedUser.description)
            } catch {
                XCTAssert(false)
            }
        }
    }

    func testUpdateUserInfoWithError() {
        let expectedError = NSError.errorForTesting()
        mockManager.expectedRequest?.expectedError = expectedError

        let user = User.userForTesting()
        api.updateUserInfo(user) { result in
            do {
                _  = try result.unwrap()

                XCTAssert(false)
            } catch let error as NSError {
                XCTAssertEqual(error, expectedError)
            }
        }
    }
}
```
Here’s the [final version of the project](https://github.com/ShengHuaWu/SimpleApiClient).

### Future Works
1. It might be better to create our custom ErrorType enum, instead of just using NSError.
2. There's no retry mechanism yet.
3. It's possible to replace Alamofire with NSURLSession.

I'm totally open to discussion and feedback, so please share your thoughts.

## Seed API Data for UI Test
When Xcode 7 was released, Apple introduced a new feature --- [UI testing](https://developer.apple.com/videos/play/wwdc2015/406/), and it allows developers to write UI tests in _Swift_ instead of Javascript. However, most of the iOS applications involve network connectivity, and UI tests with real network access will dramatically reduce the speed of these tests. Furthermore, the unreliability of the network might also make these tests non-deterministic. Recently I found out how to write [UI tests with stubbed network data](http://masilotti.com/ui-testing-stub-network-data/), and it really increases the speed of UI tests. If you are using _NSURLSession_ in your codebase, I recommend you take a look at that [series](http://masilotti.com/testing-nsurlsession-input/).

This article is an expansion of my previous article [simple iOS API client with Alamofire](https://medium.com/@shenghuawu/simple-ios-api-client-with-alamofire-cfb2cadf6c11#.v61z0vqiy). If you haven't already read my previous article, I suggest you should read it beforehand. To recap, I mentioned how to create a simple API client with Alamofire and how to write unit tests for the API client. In this article, I will introduce how to set API data for UI tests.

Please note that this article adopts Swift 2.2 and Xcode 7.3.

### Where to Insert Seed Data
Let's take a look at _XCUIApplication_'s properties `launchArguments` and `lauchEnvironment` at first. If we assign values to these properties before invoking `launch` method, we're able to retrieve the values from _NSProcessInfo_'s `arguments` and `environment` properties respectively. Thus, we can take the advantages of these properties to pass our testing data to our application during UI testing.

### Implementation
Before actually setting our testing data, we need to create _SeededManager_ and _SeededRequest_ classes that conform _ApiManagerProtocol_ and _ApiRequestProtocol_ protocols respectively.
```
final class SeededManager: ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol {
        return SeededRequest(url: endpoint.url)
    }
}

final class SeededRequest: ApiRequestProtocol {
    private let url: NSURL

    init(url: NSURL) {
        self.url = url
    }

    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        guard let jsonString = NSProcessInfo.processInfo().environment[url.absoluteString],
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {
            fatalError("Testing URL is undefined.")
        }

        do {
            let json = try JSON(data: data)
            let result: Result<JSON, NSError> = .Success(json)
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } catch {
            fatalError("Cannot parse seeded data.")
        }

        return self
    }
}
```
In SeededRequest, we retrieve the testing data from NSProcessInfo's `environment` property and invoke the completionHandler.

After implementing these two classes, we need to inject the SeededManager into our _Api_ class. Therefore, we create another struct called _Configuration_ as an injector.
```
struct Configuration {
    static var manager: ApiManagerProtocol {
        return isUITesing() ? SeededManager() : Manager.sharedInstance
    }

    private static func isUITesing() -> Bool {
        return NSProcessInfo.processInfo().arguments.contains("UI Testing")
    }
}

final class Api {
    init(manager: ApiManagerProtocol = Configuration.manager) {
        self.manager = manager
    }
    ...
}
```
We also create a static method `isUITesting` to find out if we're actually doing UI testing by check the value in NSProcessInfo's `arguments` property.

Finally, we can set the JSON response of our API in UI tests.
```
class SimpleApiClientUITests: XCTestCase {
    override func setUp() {
        super.setUp()

        let application = XCUIApplication()
        application.launchArguments.append("UI Testing")

        let parameters = ["userId" : "plokmijn",
                          "name" : "shane wu",
                          "email" : "shane.wu@gmail.com",
                          "description" : "I'm shane wu"]
        let data = try! NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions(rawValue: 0))
        let jsonString = String(data: data, encoding: NSUTF8StringEncoding)
        application.launchEnvironment["http://localhost:3000/user/plokmijn"] = jsonString
        application.launch()
    }
    ...
}
```
Here’s the [final version of the project](https://github.com/ShengHuaWu/SimpleApiClient).

### Conclusion
Frankly speaking, automating UI testing isn't a handy task because you need to tap and drag at your app’s UI to trigger changes, and you need to be able to check if these changes are correct. However, it's still important to test common workflows and demo sequences by UI testing. With seeding API data, UI tests can be run faster and cover many scenarios. Any comment and feedback are welcome, so please share your thoughts.
