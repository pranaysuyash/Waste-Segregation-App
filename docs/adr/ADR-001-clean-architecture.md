# ADR-001: Adopt Clean Architecture for Flutter Application

* Status: accepted
* Deciders: Development Team
* Date: 2025-06-20

Technical Story: Improve code maintainability, testability, and scalability by implementing Clean Architecture principles in the waste segregation Flutter app.

## Context and Problem Statement

The current Flutter application has grown organically with business logic scattered across screens, widgets, and utility files. This makes the codebase difficult to maintain, test, and scale. How can we restructure the application to improve separation of concerns, testability, and maintainability?

## Decision Drivers

* **Maintainability**: Code should be easy to understand and modify
* **Testability**: Business logic should be easily unit testable
* **Scalability**: Architecture should support adding new features without complexity explosion
* **Team Productivity**: Clear structure should reduce onboarding time and development confusion
* **Dependency Management**: External dependencies should be easily mockable and replaceable
* **Single Responsibility**: Each layer should have a clear, single purpose

## Considered Options

* **Option 1**: Keep current structure (screens/, widgets/, utils/)
* **Option 2**: Adopt Clean Architecture with feature-slice organization
* **Option 3**: Implement MVC pattern
* **Option 4**: Use MVVM pattern

## Decision Outcome

Chosen option: "Clean Architecture with feature-slice organization", because it provides the best separation of concerns, testability, and scalability for our Flutter application while maintaining clear boundaries between business logic and UI.

### Positive Consequences

* **Clear Separation**: Business logic separated from UI and external dependencies
* **Testability**: Each layer can be tested independently with proper mocking
* **Maintainability**: Changes in one layer don't cascade to others
* **Scalability**: New features can be added without affecting existing code
* **Team Clarity**: Developers know exactly where to place new code
* **Dependency Inversion**: External services can be easily swapped or mocked

### Negative Consequences

* **Initial Overhead**: Requires upfront time investment to restructure existing code
* **Learning Curve**: Team needs to understand Clean Architecture principles
* **More Files**: Feature-slice approach creates more files and folders
* **Potential Over-Engineering**: Simple features might seem complex initially

## Pros and Cons of the Options

### Option 1: Keep Current Structure

Current approach with screens/, widgets/, utils/ folders.

* Good, because requires no changes or learning
* Good, because familiar to current team
* Bad, because business logic is mixed with UI
* Bad, because difficult to unit test
* Bad, because doesn't scale well
* Bad, because high coupling between components

### Option 2: Clean Architecture with Feature-Slice

Implement Clean Architecture organized by features.

* Good, because clear separation of concerns
* Good, because highly testable
* Good, because scales well with team size
* Good, because follows industry best practices
* Good, because supports dependency inversion
* Bad, because requires initial restructuring effort
* Bad, because more complex for simple features

### Option 3: MVC Pattern

Traditional Model-View-Controller pattern.

* Good, because familiar pattern
* Good, because some separation of concerns
* Bad, because controllers can become bloated
* Bad, because tight coupling between layers
* Bad, because not optimal for Flutter's reactive nature

### Option 4: MVVM Pattern

Model-View-ViewModel pattern.

* Good, because good for data binding
* Good, because separates UI logic
* Bad, because can lead to complex ViewModels
* Bad, because not as testable as Clean Architecture
* Bad, because doesn't enforce dependency rules

## Implementation Structure

### Target Folder Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/
│   ├── classification/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   ├── gamification/
│   │   └── [same structure]
│   └── analytics/
│       └── [same structure]
└── main.dart
```

### Layer Responsibilities

1. **Domain Layer** (Business Logic)
   - Entities: Core business objects
   - Use Cases: Business rules and operations
   - Repository Interfaces: Data access contracts

2. **Data Layer** (External Interface)
   - Repository Implementations: Data access logic
   - Data Sources: API, Database, Local Storage
   - Models: Data transfer objects

3. **Presentation Layer** (UI)
   - Pages: Screen widgets
   - Widgets: Reusable UI components
   - State Management: Riverpod providers/BLoC

4. **Core Layer** (Shared)
   - Constants: App-wide constants
   - Errors: Custom exceptions
   - Utils: Helper functions
   - Network: HTTP client setup

### Migration Strategy

1. **Phase 1**: Create new structure alongside existing code
2. **Phase 2**: Migrate one feature at a time (start with classification)
3. **Phase 3**: Update imports and dependencies
4. **Phase 4**: Remove old structure once migration complete
5. **Phase 5**: Update documentation and team guidelines

## Links

* [Clean Architecture by Robert Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Flutter Clean Architecture Guide](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
* Refined by [ADR-002: State Management with Riverpod](ADR-002-state-management-riverpod.md) 