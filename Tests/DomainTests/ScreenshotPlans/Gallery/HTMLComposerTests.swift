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

    // MARK: - Conditional Blocks

    @Test func `if block renders when value is truthy`() {
        let result = HTMLComposer.render("{{#if show}}visible{{/if}}", with: ["show": "yes"])
        #expect(result == "visible")
    }

    @Test func `if block skips when value is missing`() {
        let result = HTMLComposer.render("{{#if show}}visible{{/if}}", with: [:])
        #expect(result == "")
    }

    @Test func `if block skips when value is empty string`() {
        let result = HTMLComposer.render("{{#if show}}visible{{/if}}", with: ["show": ""])
        #expect(result == "")
    }

    @Test func `if block preserves surrounding content`() {
        let result = HTMLComposer.render("before{{#if x}} middle {{/if}}after", with: ["x": "1"])
        #expect(result == "before middle after")
    }

    @Test func `if block with variable inside`() {
        let result = HTMLComposer.render("{{#if color}}<div style=\"color:{{color}}\">text</div>{{/if}}", with: ["color": "#fff"])
        #expect(result == "<div style=\"color:#fff\">text</div>")
    }

    // MARK: - Each Blocks

    @Test func `each block iterates over items`() {
        let result = HTMLComposer.render(
            "{{#each items}}<li>{{value}}</li>{{/each}}",
            with: ["items": [["value": "A"], ["value": "B"]]]
        )
        #expect(result == "<li>A</li><li>B</li>")
    }

    @Test func `each block renders empty for missing key`() {
        let result = HTMLComposer.render("{{#each items}}X{{/each}}", with: [:])
        #expect(result == "")
    }

    @Test func `each block renders empty for empty array`() {
        let result = HTMLComposer.render("{{#each items}}X{{/each}}", with: ["items": [Any]()])
        #expect(result == "")
    }

    @Test func `each block with index`() {
        let result = HTMLComposer.render(
            "{{#each items}}{{index}}:{{name}} {{/each}}",
            with: ["items": [["name": "A"], ["name": "B"]]]
        )
        #expect(result == "0:A 1:B ")
    }

    // MARK: - Nested Variables

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

    // MARK: - Whitespace Handling

    @Test func `preserves template whitespace`() {
        let template = """
        <div>
            {{content}}
        </div>
        """
        let result = HTMLComposer.render(template, with: ["content": "hello"])
        #expect(result == """
        <div>
            hello
        </div>
        """)
    }

    // MARK: - Nested If Blocks

    @Test func `nested if blocks resolve correctly`() {
        let template = "{{#if outer}}A{{#if inner}}B{{/if}}C{{/if}}"
        let result = HTMLComposer.render(template, with: ["outer": "1", "inner": "1"])
        #expect(result == "ABC")
    }

    @Test func `nested if outer true inner false`() {
        let template = "{{#if outer}}A{{#if inner}}B{{/if}}C{{/if}}"
        let result = HTMLComposer.render(template, with: ["outer": "1"])
        #expect(result == "AC")
    }

    @Test func `nested if outer false hides all`() {
        let template = "{{#if outer}}A{{#if inner}}B{{/if}}C{{/if}}"
        let result = HTMLComposer.render(template, with: [:])
        #expect(result == "")
    }

    @Test func `multiple nested ifs in sequence`() {
        let template = "{{#if w}}[{{#if a}}A{{/if}}{{#if b}}B{{/if}}]{{/if}}"
        let result = HTMLComposer.render(template, with: ["w": "1", "b": "1"])
        #expect(result == "[B]")
    }

    @Test func `nested if inside each`() {
        let template = "{{#each items}}{{#if flag}}Y{{/if}}{{#if other}}N{{/if}}-{{/each}}"
        let result = HTMLComposer.render(template, with: [
            "items": [["flag": "1"], ["other": "1"]] as [[String: Any]]
        ])
        #expect(result == "Y-N-")
    }

    // MARK: - Complex Template

    @Test func `renders screen-like template`() {
        let template = """
        <div style="background:{{background}};position:relative">{{#if tagline}}<span>{{tagline}}</span>{{/if}}<h1>{{headline}}</h1>{{#each badges}}<span class="badge">{{text}}</span>{{/each}}</div>
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
