# HipsterLorem

`HipsterLorem` is a deterministic lorem ipsum generator tuned for SwiftUI previews and tests. Instead of random gibberish every time, it emits repeatable, hipster-flavored copy so you can rely on stable layouts, hashes, and snapshots.

## Why Use It

- Keep previews, screenshots, and snapshot tests identical across runs by seeding the output.
- Exercise long-form layouts (cards, feeds, detail pages) without manually typing filler copy.
- Generate character-length targets (e.g., ~1400 characters) to validate truncation, scrolling, or typography combinations.

## Core APIs

| Call | Description |
| --- | --- |
| `words(_ count, seed:)` | Returns `count` deterministic words.
| `sentence(_ avgWords:variance:seed:)` | Builds a sentence with basic variance and punctuation.
| `paragraph(sentences:seed:)` | Concatenates several sentences into one block.
| `paragraphs(_ count, seed:)` | Produces multiple paragraphs separated by blank lines.
| `approximately(_ targetCharacters, seed:)` | Grows paragraphs until the character count meets/exceeds the target.
| `Text.hipsterLoremParagraphs(_ count, seed:)` | Convenience extension that drops the generated text straight into a `Text` view.

All functions accept a `seed` (default `1`). Changing the seed gives you a different—but still stable—result.

## Preview Example

```swift
struct ProductDetails_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Ceramic Dripper")
          .font(.title).bold()

        Text.hipsterLoremParagraphs(3, seed: 27)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
    .frame(maxWidth: 500)
  }
}
```

## Snapshot Testing Example

```swift
@Test @MainActor
func testMarketingCard() throws {
  let card = MarketingCard(description: HipsterLorem.approximately(900, seed: 99))
  assertSnapshot(view: card, device: .iOS(width: 375, height: 812))
}
```

## Tips

- Use different seeds per component to avoid obviously duplicated paragraphs in the same screen.
- Combine with `ScrollViewport` to stress-test lazy stacks or horizontal carousels using long text.
- Extend the `lexicon` array inside `HipsterLorem` to match your product's tone of voice.
