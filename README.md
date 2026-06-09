# Vocap

A vocabulary building app for iOS and macOS. Add words to your personal word bank and look up their definitions across 28 languages. Features widgets for both iPhone and Mac desktops.

## Features

- 🍎 **Sign in with Apple + iCloud** - Authentication via your Apple ID and iCloud account
- 📚 **Word Bank** - Search and save words you want to learn
- 🌍 **Multi-language Lookups** - Definitions in 28 languages (English, Spanish, French, German, and more)
- 📱 **Widgets** - Native widgets for iOS and macOS showing your vocabulary
- ☁️ **Cloud Sync** - Your words sync across all your Apple devices via CloudKit

## Tech Stack

- **UI**: SwiftUI (iOS 18.2+ / macOS 14+)
- **Backend / Sync**: CloudKit (`iCloud.com.vocap.app`)
- **Auth**: Sign in with Apple + iCloud account status (`AuthenticationServices` + `CloudKit`)
- **Local Storage**: SwiftData, shared with widgets via App Group
- **Widgets**: WidgetKit
- **Dictionary API**: [Free Dictionary API](https://freedictionaryapi.com)
- **Dependencies**: None — no external Swift packages

## Project Structure

```text
.                              # repo root
├── Vocap.xcodeproj            # open this in Xcode
├── Vocap/                     # main app sources (target: "Vocap")
│   ├── Shared/                # code shared between app and widget
│   │   ├── Models/            # data models (Word, User)
│   │   ├── Services/          # CloudKitAuthService, DictionaryService
│   │   ├── Repositories/      # local data access (SwiftData)
│   │   ├── Utilities/         # AppGroup, Constants
│   │   └── Extensions/        # Swift extensions
│   └── VocapApp/              # app entry point, Views, ViewModels, Resources
├── VocapWidget/               # widget extension (target: "VocapWidgetExtension")
├── VocapWidgetExtension.entitlements
├── VocapTests/                # unit tests
└── VocapUITests/              # UI tests
```

## Setup

The app has **no external dependencies** and uses your Apple developer account for CloudKit and App Group entitlements. There are no API keys or secrets to configure.

### 1. Open the project

Open `Vocap.xcodeproj` in **Xcode 16+** (the project targets iOS 18.2 / macOS 14, Swift 5).

### 2. Set your signing team

For each target (`Vocap`, `VocapWidgetExtension`):

1. Select the target > **Signing & Capabilities**
2. Set your **Team** and let Xcode manage signing
3. Adjust the bundle identifiers if `com.vocap.*` isn't available under your team:
   - App: `com.vocap.Vocap`
   - Widget: `com.vocap.Vocap.VocapWidget`

### 3. Verify capabilities

These should already be configured in the project, but confirm under **Signing & Capabilities**:

- **iCloud (CloudKit)** — container `iCloud.com.vocap.app`, shared by the app for sync and auth
- **App Groups** — `group.com.vocap.app`, shares the SwiftData store and widget data
- **Sign in with Apple**

If you change the bundle IDs, update the matching identifiers in
[Constants.swift](Vocap/Shared/Utilities/Constants.swift)
(`appGroupIdentifier`, `cloudKitContainerID`).

### 4. Build & Run

1. Select the **Vocap** scheme and a device/simulator
2. Build and run (⌘R)

> ℹ️ **iCloud is required at runtime.** Sign in to iCloud on your simulator/device (Settings > Sign in) — the app reports an unavailable state otherwise. CloudKit sync also requires a real iCloud account.

## Development

### Authentication flow

Auth is handled by [CloudKitAuthService.swift](Vocap/Shared/Services/CloudKitAuthService.swift):

1. On launch the app checks `CKContainer.accountStatus()`.
2. If iCloud is available, the user's CloudKit record is used as their identity.
3. Sign in with Apple supplies the display name and email, which are cached locally.

There are no passwords, magic links, or backend credentials involved.

### Dictionary lookups

[DictionaryService.swift](Vocap/Shared/Services/DictionaryService.swift) calls the
[Free Dictionary API](https://freedictionaryapi.com):

```http
GET https://freedictionaryapi.com/api/v1/entries/{language}/{word}
```

Language codes are validated against the whitelist in `Constants.DictionaryAPI.supportedLanguages`
(28 languages). No API key is required; rate limits may apply for heavy usage.

### Widget development

Widgets read from the shared App Group container (see
[AppGroup.swift](Vocap/Shared/Utilities/AppGroup.swift)). To test:

1. Build and run the **VocapWidgetExtension** scheme (or run the app once to populate shared data)
2. Add the widget to your home screen / desktop
3. Verify words appear from the shared container

The widget refreshes on the interval set in `Constants.Widget.refreshIntervalHours`.

### Testing

Run unit and UI tests from Xcode (⌘U), or from the command line:

```bash
xcodebuild test \
  -project Vocap.xcodeproj \
  -scheme Vocap \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Deployment

### App Store Submission

1. Configure your App Store Connect listing
2. Ensure CloudKit, App Groups, and Sign in with Apple are provisioned for your team
3. Test on real devices (CloudKit sync needs a real iCloud account) before submission
4. Archive and submit for review

### Required capabilities

- iCloud / CloudKit (sync and auth)
- App Groups (widget data sharing)
- Sign in with Apple

## License

MIT License - See LICENSE file for details.
