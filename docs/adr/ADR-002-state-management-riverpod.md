# ADR-002: Use Riverpod for State Management

* Status: accepted
* Deciders: Development Team
* Date: 2025-06-20

Technical Story: Establish consistent state management across the Flutter application using Riverpod for better testability, performance, and developer experience.

## Context and Problem Statement

The application currently uses a mix of state management approaches including setState, Provider, and some ad-hoc solutions. This inconsistency makes the codebase harder to maintain and test. We need to standardize on a single state management solution that works well with Clean Architecture and provides excellent testing capabilities.

## Decision Drivers

* **Consistency**: Single state management approach across the entire app
* **Testability**: Easy to mock and test state changes
* **Performance**: Efficient rebuilds and memory management
* **Developer Experience**: Good debugging tools and clear APIs
* **Clean Architecture Compatibility**: Works well with dependency injection
* **Compile-time Safety**: Catch errors at compile time rather than runtime
* **Community Support**: Active maintenance and good documentation

## Considered Options

* **Option 1**: Continue with mixed approaches (setState, Provider)
* **Option 2**: Adopt Riverpod
* **Option 3**: Use BLoC pattern
* **Option 4**: Use GetX
* **Option 5**: Use MobX

## Decision Outcome

Chosen option: "Riverpod", because it provides excellent compile-time safety, seamless integration with Clean Architecture, superior testing capabilities, and the best developer experience for our team's needs.

### Positive Consequences

* **Compile-time Safety**: Providers are checked at compile time
* **Excellent Testing**: Easy to mock providers and test state changes
* **Performance**: Automatic disposal and efficient rebuilds
* **Clean Architecture**: Perfect fit with dependency injection
* **Developer Tools**: Great debugging and inspection capabilities
* **Future-proof**: Active development and Flutter team support

### Negative Consequences

* **Learning Curve**: Team needs to learn Riverpod concepts
* **Migration Effort**: Existing Provider code needs migration
* **Boilerplate**: Some additional code for provider definitions

## Pros and Cons of the Options

### Option 1: Mixed Approaches

Continue with current setState and Provider mix.

* Good, because no migration needed
* Good, because team already familiar
* Bad, because inconsistent patterns
* Bad, because harder to test
* Bad, because poor scalability
* Bad, because maintenance overhead

### Option 2: Riverpod

Modern state management with compile-time safety.

* Good, because compile-time safety
* Good, because excellent testing support
* Good, because great performance
* Good, because clean dependency injection
* Good, because active development
* Bad, because learning curve
* Bad, because migration effort required

### Option 3: BLoC Pattern

Business Logic Component pattern.

* Good, because clear separation of concerns
* Good, because testable
* Good, because predictable state changes
* Bad, because verbose boilerplate
* Bad, because steeper learning curve
* Bad, because overkill for simple state

### Option 4: GetX

All-in-one solution for state, routing, and dependencies.

* Good, because minimal boilerplate
* Good, because high performance
* Bad, because too opinionated
* Bad, because couples multiple concerns
* Bad, because harder to test
* Bad, because not following Flutter conventions

### Option 5: MobX

Reactive state management.

* Good, because reactive programming
* Good, because minimal boilerplate for simple cases
* Bad, because code generation complexity
* Bad, because less Flutter-specific
* Bad, because smaller community

## Implementation Guidelines

### Provider Types

1. **StateProvider**: For simple state (counters, flags)
2. **StateNotifierProvider**: For complex state with business logic
3. **FutureProvider**: For async operations
4. **StreamProvider**: For reactive data streams
5. **Provider**: For immutable values and services

### Naming Conventions

```dart
// Providers
final userProvider = StateNotifierProvider<UserNotifier, User>(...);
final settingsProvider = StateProvider<Settings>(...);

// Notifiers
class UserNotifier extends StateNotifier<User> { ... }
class SettingsNotifier extends StateNotifier<Settings> { ... }
```

### Folder Structure Integration

```
lib/
├── features/
│   └── classification/
│       └── presentation/
│           ├── providers/
│           │   ├── classification_provider.dart
│           │   └── classification_notifier.dart
│           └── pages/
│               └── classification_page.dart
```

### Testing Patterns

```dart
// Provider testing
testWidgets('should update state when action performed', (tester) async {
  final container = ProviderContainer();
  
  // Override provider for testing
  final notifier = container.read(classificationProvider.notifier);
  
  // Test state changes
  expect(container.read(classificationProvider), initialState);
  
  await notifier.performAction();
  
  expect(container.read(classificationProvider), expectedState);
});
```

### Integration with Clean Architecture

```dart
// Use case provider
final classificationUseCaseProvider = Provider<ClassificationUseCase>((ref) {
  return ClassificationUseCase(
    repository: ref.read(classificationRepositoryProvider),
  );
});

// State notifier using use case
class ClassificationNotifier extends StateNotifier<ClassificationState> {
  final ClassificationUseCase _useCase;
  
  ClassificationNotifier(this._useCase) : super(ClassificationState.initial());
  
  Future<void> classifyImage(String imagePath) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _useCase.classifyImage(imagePath);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (classification) => state = state.copyWith(
        isLoading: false,
        classification: classification,
      ),
    );
  }
}
```

### Migration Strategy

1. **Phase 1**: Add Riverpod dependency and setup
2. **Phase 2**: Create providers for new features
3. **Phase 3**: Migrate existing Provider code to Riverpod
4. **Phase 4**: Update tests to use Riverpod patterns
5. **Phase 5**: Remove old Provider dependencies

## Links

* [Riverpod Documentation](https://riverpod.dev/)
* [Riverpod vs Provider](https://riverpod.dev/docs/from_provider/motivation)
* Refines [ADR-001: Clean Architecture](ADR-001-clean-architecture.md) 