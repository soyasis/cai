import XCTest
@testable import Cai

final class ContentDetectorTests: XCTestCase {

    private var detector: ContentDetector!

    override func setUp() {
        super.setUp()
        detector = ContentDetector.shared
    }

    // MARK: - URL Detection

    func testDetectsHTTPSUrl() {
        let result = detector.detect("https://example.com")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.confidence, 1.0)
        XCTAssertEqual(result.entities.url, "https://example.com")
    }

    func testDetectsHTTPUrl() {
        let result = detector.detect("http://example.com")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "http://example.com")
    }

    func testDetectsUrlWithPath() {
        let result = detector.detect("https://example.com/path/to/page")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "https://example.com/path/to/page")
    }

    func testDetectsUrlWithQueryParams() {
        let result = detector.detect("https://example.com/search?q=test&page=1")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "https://example.com/search?q=test&page=1")
    }

    func testDetectsUrlWithFragment() {
        let result = detector.detect("https://example.com/docs#section-2")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "https://example.com/docs#section-2")
    }

    func testDetectsWwwUrl() {
        let result = detector.detect("www.example.com")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.confidence, 1.0)
        XCTAssertEqual(result.entities.url, "https://www.example.com")
    }

    func testDetectsUrlWithSurroundingText() {
        let result = detector.detect("Check out https://example.com/cool for details")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "https://example.com/cool")
    }

    // MARK: - JSON Detection

    func testDetectsSimpleJSONObject() {
        let result = detector.detect(#"{"name": "test", "value": 42}"#)
        XCTAssertEqual(result.type, .json)
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testDetectsJSONArray() {
        let result = detector.detect(#"[1, 2, 3, "four"]"#)
        XCTAssertEqual(result.type, .json)
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testDetectsNestedJSON() {
        let json = """
        {
            "user": {
                "name": "Alice",
                "settings": {
                    "theme": "dark"
                }
            }
        }
        """
        let result = detector.detect(json)
        XCTAssertEqual(result.type, .json)
    }

    func testDetectsJSONWithTrailingComma() {
        let result = detector.detect(#"{"name": "test", "value": 42},"#)
        XCTAssertEqual(result.type, .json)
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testDetectsJSONArrayWithTrailingComma() {
        let result = detector.detect(#"[1, 2, 3],"#)
        XCTAssertEqual(result.type, .json)
    }

    func testRejectsInvalidJSON() {
        let result = detector.detect("{not valid json at all}")
        XCTAssertNotEqual(result.type, .json)
    }

    func testRejectsTextStartingWithBrace() {
        // This starts with { but is not JSON
        let result = detector.detect("{smile} is an emoji code")
        XCTAssertNotEqual(result.type, .json)
    }

    // MARK: - Address Detection

    func testDetectsUSStreetAddress() {
        let result = detector.detect("123 Main Street, Springfield, IL 62701")
        XCTAssertEqual(result.type, .address)
        XCTAssertEqual(result.confidence, 0.8)
        XCTAssertNotNil(result.entities.address)
    }

    func testDetectsUSAbbreviatedAddress() {
        let result = detector.detect("456 Oak Ave")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsAddressWithBlvd() {
        let result = detector.detect("789 Sunset Boulevard")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsAddressWithDrive() {
        let result = detector.detect("1200 Technology Drive, Suite 100")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsSpanishAddress() {
        let result = detector.detect("42 Calle Mayor, Madrid")
        XCTAssertEqual(result.type, .address)
        XCTAssertNotNil(result.entities.address)
    }

    func testDetectsGermanAddress() {
        let result = detector.detect("15 Berliner Strasse")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsGermanStrasseAddress() {
        let result = detector.detect("23 Hauptstrasse, Berlin")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsItalianAddress() {
        let result = detector.detect("7 Via Roma, Milano")
        XCTAssertEqual(result.type, .address)
    }

    func testDetectsFrenchAddress() {
        let result = detector.detect("12 Rue de la Paix")
        XCTAssertEqual(result.type, .address)
    }

    // MARK: - Date/Meeting Detection

    func testDetectsTomorrowAt3pm() {
        let result = detector.detect("tomorrow at 3pm")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.date)
        XCTAssertNotNil(result.entities.dateText)
    }

    func testDetectsNextTuesday() {
        let result = detector.detect("next Tuesday")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.date)
    }

    func testDetectsSpecificDate() {
        let result = detector.detect("March 3rd at 2:30")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.date)
    }

    func testDetectsEuropeanTimeFormat() {
        let result = detector.detect("March 3rd at 14h")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.date)
    }

    func testDetectsMeetingWithKeyword() {
        let result = detector.detect("meeting tomorrow at 3pm")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
    }

    func testDetectsLunchMeeting() {
        let result = detector.detect("lunch on Friday")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.date)
    }

    func testDetectsCoffeeChat() {
        let result = detector.detect("coffee chat next Monday")
        XCTAssertEqual(result.type, .meeting)
    }

    func testDetectsMeetingWithLocation() {
        let result = detector.detect("meeting tomorrow at Starbucks")
        XCTAssertEqual(result.type, .meeting)
        XCTAssertNotNil(result.entities.location)
    }

    // MARK: - False Positive Filtering

    func testFiltersCurrencyDollar() {
        let result = detector.detect("$50")
        XCTAssertNotEqual(result.type, .meeting)
    }

    func testFiltersCurrencyEuro() {
        let result = detector.detect("€200")
        XCTAssertNotEqual(result.type, .meeting)
    }

    func testFiltersCurrencyPound() {
        let result = detector.detect("£100")
        XCTAssertNotEqual(result.type, .meeting)
    }

    func testFiltersDurationMinutes() {
        let result = detector.detect("for 5 minutes")
        XCTAssertNotEqual(result.type, .meeting)
    }

    func testFiltersDurationHours() {
        let result = detector.detect("about 2 hours")
        XCTAssertNotEqual(result.type, .meeting)
    }

    func testFiltersDurationApprox() {
        let result = detector.detect("approximately 30 seconds")
        XCTAssertNotEqual(result.type, .meeting)
    }

    // MARK: - Text Classification

    func testClassifiesSingleWord() {
        let result = detector.detect("Hello")
        XCTAssertEqual(result.type, .word)
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testClassifiesTwoWords() {
        let result = detector.detect("Hello World")
        XCTAssertEqual(result.type, .word)
    }

    func testClassifiesShortText() {
        let result = detector.detect("This is a short sentence that is under one hundred characters long.")
        XCTAssertEqual(result.type, .shortText)
    }

    func testClassifiesLongText() {
        let longText = String(repeating: "This is a longer piece of text. ", count: 10)
        XCTAssertGreaterThanOrEqual(longText.count, 100)
        let result = detector.detect(longText)
        XCTAssertEqual(result.type, .longText)
    }

    func testEmptyStringClassifiesAsShortText() {
        let result = detector.detect("")
        XCTAssertEqual(result.type, .shortText)
    }

    func testWhitespaceOnlyClassifiesAsShortText() {
        let result = detector.detect("   \n\t  ")
        XCTAssertEqual(result.type, .shortText)
    }

    // MARK: - Priority / Short-circuit Tests

    func testURLTakesPriorityOverText() {
        // A URL is also short text, but URL should win
        let result = detector.detect("https://x.com")
        XCTAssertEqual(result.type, .url)
    }

    func testJSONTakesPriorityOverText() {
        let result = detector.detect(#"{"a": 1}"#)
        XCTAssertEqual(result.type, .json)
    }

    func testAddressTakesPriorityOverText() {
        let result = detector.detect("123 Main Street")
        XCTAssertEqual(result.type, .address)
    }

    // MARK: - Edge Cases

    func testTrimsWhitespaceBeforeDetection() {
        let result = detector.detect("  https://example.com  \n")
        XCTAssertEqual(result.type, .url)
    }

    func testComplexURL() {
        let result = detector.detect("https://api.example.com/v2/users?id=123&token=abc#profile")
        XCTAssertEqual(result.type, .url)
        XCTAssertEqual(result.entities.url, "https://api.example.com/v2/users?id=123&token=abc#profile")
    }

    func testMinifiedJSON() {
        let result = detector.detect(#"{"a":1,"b":[2,3],"c":{"d":true}}"#)
        XCTAssertEqual(result.type, .json)
    }

    func testWordBoundary() {
        // "29 chars here but two words" — 2 words, under 30 chars
        let result = detector.detect("ab cd")
        XCTAssertEqual(result.type, .word)
    }

    func testThreeWordsIsShortText() {
        let result = detector.detect("one two three")
        XCTAssertEqual(result.type, .shortText)
    }
}
