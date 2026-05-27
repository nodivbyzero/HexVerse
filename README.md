# HexVerse

A macOS screensaver that animates R package hex stickers in a honeycomb grid. Stickers grow from a single point, hold, then fade out — each at its own random speed.

## Installation

### Download
1. Download `HexVerse.saver` from the [Releases](../../releases) page
2. Double-click `HexVerse.saver` — macOS will ask to install it
3. Open **System Settings → Screen Saver** and select **HexVerse**

### Build from source
Requirements: Xcode 16+, macOS 14+

```bash
git clone https://github.com/nodivbyzero/HexVerse.git
cd HexVerse
open HexSaverTestbed.xcodeproj
```

Select the **HexVerse** scheme and build (`⌘B`). The `.saver` bundle will appear in `DerivedData`. Double-click to install.

## Adding your own stickers

Drop any `.png` files into the `stickers/` folder and rebuild. The screensaver picks them up automatically — no code changes needed.

Sticker images should ideally be hex-shaped PNGs with a transparent background, but any PNG works — it gets clipped to a hex shape at runtime.

## Stickers

Hex stickers included in this repo are from the [rstudio/hex-stickers](https://github.com/rstudio/hex-stickers) collection, licensed under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/) — public domain, no attribution required.


## License

MIT — see [LICENSE](LICENSE)
