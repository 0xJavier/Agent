# [Your App Name] - iOS Project

## Project Overview

[Brief description of your app - what it does, who it's for, key features]

Example:
> This is a [consumer/enterprise] iOS app that [main purpose]. Key features include [feature 1], [feature 2], and [feature 3].

## Tech Stack

- **UI Framework**: SwiftUI (iOS 16+)
- **Architecture**: MVVM with Coordinators
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Networking**: URLSession with custom APIClient
- **Analytics**: [Your analytics provider - e.g., Firebase, Amplitude, Mixpanel]
- **Dependencies**: Swift Package Manager

## Coding Guidelines

### Swift Style
- Use Swift's latest language features (async/await, actors, structured concurrency)
- Prefer value types (structs) over reference types (classes) unless shared mutable state is needed
- Use `private` by default, expose only what's necessary
- Mark classes as `final` unless designed for inheritance

### Naming Conventions
- Types: `UpperCamelCase` (e.g., `UserProfileView`, `NetworkService`)
- Properties/Methods: `lowerCamelCase` (e.g., `userName`, `fetchData()`)
- Constants: `lowerCamelCase` (not `SCREAMING_SNAKE_CASE`)
- Boolean properties: Use `is`, `has`, `should` prefixes (e.g., `isLoading`, `hasError`)

### SwiftUI Specifics
- Extract subviews when a view exceeds ~50 lines
- Use `@ViewBuilder` for conditional view logic
- Prefer composition over complex conditional chains
- Keep view bodies focused on layout, move logic to ViewModels

### Error Handling
- Use typed errors conforming to `Error` protocol
- Prefer `Result` type or throwing functions over optionals for operations that can fail
- Always handle errors explicitly, never silently ignore

## Project Structure

```
[YourApp]/
├── App/                    # App entry point and configuration
├── Features/               # Feature modules (one folder per feature)
│   └── [FeatureName]/
│       ├── Views/          # SwiftUI views
│       ├── ViewModels/     # View models
│       └── Models/         # Feature-specific models
├── Core/                   # Shared core functionality
│   ├── Networking/         # API client and endpoints
│   ├── Analytics/          # Analytics tracking
│   └── Extensions/         # Swift/SwiftUI extensions
├── DesignSystem/           # Reusable UI components
└── Resources/              # Assets, localization, etc.
```

## Available Skills

This project has specialized skills for common tasks. Copilot will automatically load them when relevant:

- **analytics**: How we track events and user actions
- **swiftui-views**: Patterns for creating consistent SwiftUI views
- **accessibility**: Requirements for VoiceOver and accessibility support
- **networking**: How to add new API endpoints and handle network requests

## Resources

- Run tests: `⌘+U` in Xcode or `xcodebuild test`
- SwiftLint is configured for code style enforcement
- All PRs require passing tests and SwiftLint checks
