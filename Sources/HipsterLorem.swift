import SwiftUI

// MARK: - Hipster Lorem

public struct HipsterLorem {
    /// Deterministic lorem for previews. Change `seed` to get a different, but stable, result.
    public static func words(_ count: Int, seed: UInt64 = 1) -> String {
        var rng = SeededGenerator(seed: seed)
        return (0..<count).map { _ in lexicon.randomElement(using: &rng)! }.joined(separator: " ")
    }

    public static func sentence(_ avgWords: Int = 12, variance: Int = 4, seed: UInt64 = 1) -> String {
        var rng = SeededGenerator(seed: seed)
        let w = max(3, avgWords + Int.random(in: -variance...variance, using: &rng))
        let s = words(w, seed: rng.next())
        return s.prefix(1).capitalized + s.dropFirst() + "."
    }

    public static func paragraph(sentences: Int = 4, seed: UInt64 = 1) -> String {
        var rng = SeededGenerator(seed: seed)
        return (0..<sentences).map { i in
            sentence(12, variance: 5, seed: rng.next() &+ UInt64(i))
        }.joined(separator: " ")
    }

    /// Build many paragraphs separated by blank lines.
    public static func paragraphs(_ count: Int, seed: UInt64 = 1) -> String {
        var rng = SeededGenerator(seed: seed)
        return (0..<count).map { i in
            paragraph(sentences: 3 + Int(i % 3), seed: rng.next())
        }.joined(separator: "\n\n")
    }

    /// Roughly target a character length by growing paragraphs until we exceed `target`.
    public static func approximately(_ targetCharacters: Int, seed: UInt64 = 1) -> String {
        var rng = SeededGenerator(seed: seed)
        var text = ""
        while text.count < targetCharacters {
            let p = paragraph(sentences: Int.random(in: 3...6, using: &rng), seed: rng.next())
            text += (text.isEmpty ? "" : "\n\n") + p
        }
        return text
    }

    // A small but flavorful hipster lexicon. Add/trim to taste.
    private static let lexicon: [String] = [
        "artisan","cold-brew","vintage","locavore","glossier","normcore","sous-vide","bespoke",
        "small-batch","shiplap","biodynamic","moleskine","retro","brunch","charcoal","gluten-free",
        "tumeric","pour-over","gen-z","typewriter","single-origin","fixie","vinyl","succulent",
        "kombucha","brooklyn","banh-mi","umami","poke","ramen","campfire","moonshot","zine","wanderlust",
        "asymmetrical","microdose","heirloom","quartz","darkroom","letterpress","seitan","miso","matcha",
        "sustainable","upcycled","thrifted","raw-denim","athleisure","co-working","biophilic","foam-core",
        "mocktail","polaroid","sourdough","wildflower","linen","macchiato","copper","substack","lo-fi",
        "vibe","beam","loam","clay","terracotta","sun-drenched","hand-thrown","monochrome","geo",
        "farmhouse","drip","stencil","flat white","neon","cerulean","fern","latte","patina","grain",
        "oak","walnut","studio","hazy","studio-light","softbox","silhouette","grainy","bokeh"
    ]
}

// MARK: - Deterministic RNG (for repeatable previews)

public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    public mutating func next() -> UInt64 {
        // xorshift64*
        var x = state
        x ^= x >> 12; x ^= x << 25; x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}

// MARK: - SwiftUI convenience

public extension Text {
    /// Easily drop long, deterministic hipster lorem into a Text view.
    static func hipsterLoremParagraphs(_ count: Int = 3, seed: UInt64 = 1) -> Text {
        Text(HipsterLorem.paragraphs(count, seed: seed))
    }
}

#Preview("Hipster lorem in a Card") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Product Description")
                .font(.title2).bold()

            Text.hipsterLoremParagraphs(4, seed: 42)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            Text(HipsterLorem.approximately(1400, seed: 99))
                .font(.callout)
        }
        .padding()
    }
    .frame(maxWidth: 600)
}
