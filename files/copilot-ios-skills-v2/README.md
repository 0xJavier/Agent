# GitHub Copilot iOS Skills

Skills for iOS/SwiftUI. Copilot loads them automatically based on your prompt.

## Structure

```
.github/
├── copilot-instructions.md           # Global (always active)
└── skills/
    ├── swiftui-views/
    │   ├── SKILL.md                  # Views, components, ViewModels
    │   └── examples/YourPatterns.md  # YOUR code
    ├── networking/
    │   ├── SKILL.md                  # API, services, mocks
    │   └── examples/YourPatterns.md
    ├── analytics/
    │   ├── SKILL.md                  # Event tracking
    │   └── examples/YourPatterns.md
    ├── unit-testing/
    │   ├── SKILL.md                  # Tests, mocks
    │   └── examples/YourPatterns.md
    └── accessibility/
        ├── SKILL.md                  # VoiceOver, Dynamic Type
        └── examples/YourPatterns.md
```

## How It Works

Skills load **automatically** based on your prompt:

| Prompt mentions... | Skill loaded |
|-------------------|--------------|
| view, component, ViewModel | swiftui-views |
| API, endpoint, service | networking |
| analytics, track, event | analytics |
| test, mock | unit-testing |
| accessibility, VoiceOver | accessibility |

## Setup

1. **Copy to your project:**
   ```bash
   cp -r .github/ /path/to/your/project/.github/
   ```

2. **Enable in VS Code:**
   ```json
   { "chat.useAgentSkills": true }
   ```

3. **Add your code to `examples/YourPatterns.md` files**

## Example Prompts

- Create a ProfileView with avatar and stats
- Add analytics for screen views
- Write tests for ProfileViewModel
- Review for accessibility issues
- Create UserService with CRUD endpoints

## Key: Your Examples

Edit `examples/YourPatterns.md` in each skill with YOUR code patterns.
