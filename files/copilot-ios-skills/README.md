# GitHub Copilot iOS/SwiftUI Skills

Custom instructions and prompts to make GitHub Copilot an expert iOS developer that codes to YOUR standards.

## 📁 Structure

```
.github/
├── copilot-instructions.md          # 🌐 GLOBAL - Always applied
├── swiftui.instructions.md          # 🎨 SwiftUI views/components  
├── networking.instructions.md       # 🌐 API/Network code
├── analytics.instructions.md        # 📊 Analytics tracking
├── testing.instructions.md          # 🧪 Unit tests
└── prompts/                         # 🎯 On-demand tasks
    ├── create-view.prompt.md
    ├── create-viewmodel.prompt.md
    ├── create-component.prompt.md
    ├── create-api.prompt.md
    ├── create-tests.prompt.md
    ├── add-analytics.prompt.md
    └── accessibility-review.prompt.md

docs/
└── examples/                        # ⭐ YOUR CODE STANDARDS GO HERE
    ├── ViewExamples.md
    ├── ViewModelExamples.md
    ├── NetworkExamples.md
    └── TestExamples.md
```

## 🔧 How It Works

### Instructions (Automatic)

Files ending in `.instructions.md` are **automatically applied** based on the `applyTo` pattern:

| File | Applied When Editing |
|------|---------------------|
| `copilot-instructions.md` | All files (no applyTo = global) |
| `swiftui.instructions.md` | `**/Views/**`, `**/*View.swift` |
| `networking.instructions.md` | `**/Network/**`, `**/*Service.swift` |
| `analytics.instructions.md` | `**/Analytics/**`, `**/*Analytics*.swift` |
| `testing.instructions.md` | `**/*Tests.swift`, `**/Tests/**` |

### Prompts (On-Demand)

Files in `prompts/` are triggered manually in Copilot Chat:

```
/create-view
/create-viewmodel
/create-api
/create-tests
/add-analytics
/accessibility-review
/create-component
```

## ⭐ Adding Your Code Standards

**This is the key step!** The `docs/examples/` folder is where you teach Copilot YOUR patterns.

### Step 1: Open an example file

```
docs/examples/ViewExamples.md
```

### Step 2: Replace TODOs with your actual code

**Before:**
```markdown
## Your View Template
\`\`\`swift
// TODO: Add your standard view template here
\`\`\`
```

**After:**
```markdown
## Your View Template
\`\`\`swift
import SwiftUI

struct FeatureView: View {
    @State private var viewModel: FeatureViewModel
    
    init(viewModel: FeatureViewModel = .init()) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ContentView(viewModel: viewModel)
            .task { await viewModel.onAppear() }
    }
}

private struct ContentView: View {
    @Bindable var viewModel: FeatureViewModel
    
    var body: some View {
        // We always use ScrollView as root
        ScrollView {
            // Content here
        }
    }
}
\`\`\`
```

### Step 3: Repeat for each example file

- `ViewExamples.md` - Your view patterns
- `ViewModelExamples.md` - Your ViewModel patterns  
- `NetworkExamples.md` - Your API patterns
- `TestExamples.md` - Your testing patterns

## 📋 Quick Setup

1. **Copy to your project:**
   ```bash
   cp -r .github/ /path/to/your/project/.github/
   cp -r docs/ /path/to/your/project/docs/
   ```

2. **Enable in VS Code settings:**
   ```json
   {
     "github.copilot.chat.codeGeneration.useInstructionFiles": true
   }
   ```

3. **Fill in your examples:**
   Edit each file in `docs/examples/` with your actual code patterns.

4. **Start using:**
   - Edit Swift files → Instructions auto-apply
   - Use `/create-view` in chat → Prompts trigger

## 💡 Tips

- **Be specific in examples** - Include comments explaining WHY you do things
- **Show bad patterns too** - `// ❌ Don't do this` helps Copilot avoid mistakes
- **Keep examples focused** - One clear pattern per section
- **Update as you evolve** - Your standards change, update the examples

## 🔍 Verification

Check if instructions are being used:
1. Open Copilot Chat
2. Look at the "References" section of responses
3. You should see your instruction files listed
