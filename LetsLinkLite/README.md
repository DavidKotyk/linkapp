# linkapp (Swift iOS App)

## Overview
`linkapp` is a SwiftUI-based iOS client for the LetsLinkLite social events platform. It displays nearby events on a map, lets you view event details, chat, and manage profiles.

## Debug Agent Screen
In **DEBUG** builds, there’s a hidden debug screen that scrapes Facebook mobile events and displays the raw list of event titles.

1. Launch the app in the **Debug** scheme on the iOS Simulator or device.
2. Go to the **Profile** tab.
3. Tap the **Debug Agent** button (visible only in DEBUG builds).
4. The debug view will:
   - Load `https://m.facebook.com/events` in a WKWebView.
   - Run a JavaScript extractor to pull all event link titles.
   - Display scraped event titles in a List below the WebView.

You can inspect the live Facebook page in the embedded WebView and see extracted titles immediately.

## Cookie Persistence (Advanced)
To bypass manual login in the debug agent:
1. Seed a `cookies.json` file via the Python ScraperAgent (`seed_cookies_simple.py`).
2. Add `cookies.json` to the app bundle (Copy Bundle Resources).
3. The debug view will auto-load these cookies into the WKWebView on launch.

When cookies expire, the debug agent will fall back to manual login in the WebView.

## Requirements
- Xcode 15+
- iOS 17+ deployment target

## Building & Running
1. Open `LetsLinkLite.xcodeproj` in Xcode.
2. Select the **Debug** scheme.
3. Build & Run on Simulator or device.

## Next Steps
- Integrate a real events scraper instead of the debug JS snippet.
- Wire up live event data into production build.
