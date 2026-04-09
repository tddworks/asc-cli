import Foundation
import Testing
@testable import Domain

@Suite("HTMLComposer")
struct HTMLComposerTests {

    // MARK: - Variable Substitution

    @Test func `replaces simple variable`() {
        let result = HTMLComposer.render("Hello {{name}}!", with: ["name": "World"])
        #expect(result == "Hello World!")
    }

    @Test func `replaces multiple variables`() {
        let result = HTMLComposer.render("{{a}} and {{b}}", with: ["a": "X", "b": "Y"])
        #expect(result == "X and Y")
    }

    @Test func `missing variable renders empty`() {
        let result = HTMLComposer.render("Hello {{missing}}!", with: [:])
        #expect(result == "Hello !")
    }

    @Test func `replaces same variable multiple times`() {
        let result = HTMLComposer.render("{{x}}-{{x}}", with: ["x": "ok"])
        #expect(result == "ok-ok")
    }

    // MARK: - Sections (if/each)

    @Test func `section renders when value is truthy`() {
        let result = HTMLComposer.render("{{#show}}visible{{/show}}", with: ["show": true])
        #expect(result == "visible")
    }

    @Test func `section skips when value is missing`() {
        let result = HTMLComposer.render("{{#show}}visible{{/show}}", with: [:])
        #expect(result == "")
    }

    @Test func `section renders when value is empty string`() {
        // Mustache treats any non-nil value as truthy (including empty string)
        let result = HTMLComposer.render("{{#show}}visible{{/show}}", with: ["show": ""])
        #expect(result == "visible")
    }

    @Test func `section preserves surrounding content`() {
        let result = HTMLComposer.render("before{{#x}} middle {{/x}}after", with: ["x": "1"])
        #expect(result == "before middle after")
    }

    @Test func `section with variable inside`() {
        let result = HTMLComposer.render("{{#color}}<div style=\"color:{{color}}\">text</div>{{/color}}", with: ["color": "#fff"])
        #expect(result == "<div style=\"color:#fff\">text</div>")
    }

    // MARK: - Array Iteration

    @Test func `section iterates over array items`() {
        let result = HTMLComposer.render(
            "{{#items}}<li>{{value}}</li>{{/items}}",
            with: ["items": [["value": "A"], ["value": "B"]]]
        )
        #expect(result == "<li>A</li><li>B</li>")
    }

    @Test func `section renders empty for missing key`() {
        let result = HTMLComposer.render("{{#items}}X{{/items}}", with: [:])
        #expect(result == "")
    }

    @Test func `section renders empty for empty array`() {
        let result = HTMLComposer.render("{{#items}}X{{/items}}", with: ["items": [Any]()])
        #expect(result == "")
    }

    // MARK: - Nested Sections

    @Test func `nested sections resolve correctly`() {
        let result = HTMLComposer.render("{{#outer}}A{{#inner}}B{{/inner}}C{{/outer}}", with: ["outer": true, "inner": true])
        #expect(result == "ABC")
    }

    @Test func `nested section outer true inner false`() {
        let result = HTMLComposer.render("{{#outer}}A{{#inner}}B{{/inner}}C{{/outer}}", with: ["outer": true])
        #expect(result == "AC")
    }

    @Test func `nested section outer false hides all`() {
        let result = HTMLComposer.render("{{#outer}}A{{#inner}}B{{/inner}}C{{/outer}}", with: [:])
        #expect(result == "")
    }

    @Test func `multiple nested sections in sequence`() {
        let result = HTMLComposer.render("{{#w}}[{{#a}}A{{/a}}{{#b}}B{{/b}}]{{/w}}", with: ["w": true, "b": true])
        #expect(result == "[B]")
    }

    // MARK: - Dot Notation

    @Test func `dot notation accesses nested values`() {
        let ctx: [String: Any] = ["slot": ["y": "10", "size": "5"]]
        let result = HTMLComposer.render("top:{{slot.y}}%;font-size:{{slot.size}}cqi", with: ctx)
        #expect(result == "top:10%;font-size:5cqi")
    }

    // MARK: - Raw Output

    @Test func `triple braces output raw value`() {
        let result = HTMLComposer.render("{{{content}}}", with: ["content": "<b>bold</b>"])
        #expect(result == "<b>bold</b>")
    }

    // MARK: - Complex Template

    @Test func `renders screen-like template`() {
        let template = """
        <div style="background:{{background}};position:relative">{{#tagline}}<span>{{tagline}}</span>{{/tagline}}<h1>{{headline}}</h1>{{#badges}}<span class="badge">{{text}}</span>{{/badges}}</div>
        """
        let ctx: [String: Any] = [
            "background": "#000",
            "headline": "Ship Faster",
            "badges": [["text": "New"], ["text": "Hot"]],
        ]
        let result = HTMLComposer.render(template, with: ctx)
        #expect(result == """
        <div style="background:#000;position:relative"><h1>Ship Faster</h1><span class="badge">New</span><span class="badge">Hot</span></div>
        """)
    }
}
