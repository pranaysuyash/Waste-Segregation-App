# User Flow Diagram Templates
*Last Updated: December 2024*

This document provides Mermaid diagram templates and examples for visualizing the comprehensive user flows catalog. Use these templates to create detailed flow diagrams for development and design teams.

## Template Structure

### Basic Flow Template
```mermaid
flowchart TD
    A[Start State] --> B{Decision Point}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End State]
    D --> E
```

### Multi-Actor Flow Template
```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant S as Server
    participant E as External Service
    
    U->>A: Action
    A->>S: Request
    S->>E: API Call
    E-->>S: Response
    S-->>A: Data
    A-->>U: Result
```

## Core Flow Examples

### 1. Batch Scan Mode Flow
```mermaid
flowchart TD
    A[Home Screen] --> B[Hold Scan FAB]
    B --> C[Multi-Capture Mode]
    C --> D{Items < 10?}
    D -->|Yes| E[Capture Image]
    E --> F[Add to Gallery]
    F --> D
    D -->|No| G[Gallery Full]
    G --> H[Bulk Analyze]
    D -->|Done| H
    H --> I[Show Loading]
    I --> J[AI Processing]
    J --> K[Results Grid]
    K --> L{Select Item?}
    L -->|Yes| M[Item Detail]
    L -->|No| N[Save All to History]
    M --> O[Individual Actions]
    O --> N
    N --> P[Impact Summary]
    P --> Q[End]
```

### 2. Voice Classification Flow
```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant V as Voice Service
    participant AI as AI Classifier
    participant TTS as Text-to-Speech
    
    U->>A: Tap Voice Icon
    A->>A: Show Voice Overlay
    A->>A: Request Microphone Permission
    U->>A: Speak Item Name
    A->>V: Audio Stream
    V->>V: Speech Recognition
    V-->>A: Text Result
    A->>AI: Classify Text
    AI-->>A: Classification Result
    A->>TTS: Generate Audio Response
    TTS-->>A: Audio Response
    A->>A: Display Visual Result
    A->>U: Play Audio + Show Result
```

### 3. Daily Eco-Quest Flow
```mermaid
stateDiagram-v2
    [*] --> QuestAvailable
    QuestAvailable --> QuestStarted : User accepts quest
    QuestStarted --> InProgress : Begin tracking
    InProgress --> ItemScanned : User scans item
    ItemScanned --> ProgressUpdated : Check quest criteria
    ProgressUpdated --> InProgress : Not complete
    ProgressUpdated --> QuestCompleted : Criteria met
    QuestCompleted --> RewardEarned : Award points/badge
    RewardEarned --> [*]
    
    InProgress --> QuestExpired : Time limit reached
    QuestExpired --> [*]
```

### 4. AR Sorting Guidance Flow
```mermaid
flowchart LR
    A[Scan Result] --> B{AR Available?}
    B -->|No| C[Show Standard Result]
    B -->|Yes| D[Show AR Button]
    D --> E[User Taps AR]
    E --> F[Request Camera Permission]
    F --> G[Initialize AR Session]
    G --> H[Detect Surfaces]
    H --> I[Show Live Camera]
    I --> J[Overlay Sorting Arrows]
    J --> K[Track Item Movement]
    K --> L{Correct Bin?}
    L -->|Yes| M[Show Success Animation]
    L -->|No| N[Show Guidance Arrow]
    N --> K
    M --> O[Update Impact Score]
    O --> P[End AR Session]
    P --> Q[Return to Results]
```

## Advanced Flow Examples

### 5. IoT Bin Monitoring Flow
```mermaid
graph TB
    subgraph "Smart Home Ecosystem"
        A[Smart Bin Sensor] --> B[Weight/Fill Level Data]
        B --> C[IoT Gateway]
        C --> D[Cloud Platform]
    end
    
    subgraph "WasteWise App"
        E[App Dashboard] --> F[Bin Status Widget]
        F --> G{Bin Full?}
        G -->|Yes| H[Pickup Notification]
        G -->|No| I[Normal Status]
        H --> J[Schedule Pickup]
        J --> K[Municipal API]
        K --> L[Pickup Confirmed]
    end
    
    D --> E
    L --> M[Update User]
```

### 6. Community Cleanup Event Flow
```mermaid
journey
    title Community Cleanup Event Journey
    section Planning
      Open Community Tab: 5: User
      Create Event: 3: User
      Set Location/Date: 4: User
      Invite Participants: 5: User
    section Event Day
      Check-in at Location: 4: Participants
      Start Cleanup Tracking: 5: Organizer
      Scan Items Found: 5: Participants
      Real-time Leaderboard: 4: All
    section Completion
      View Impact Summary: 5: All
      Share Achievements: 4: All
      Plan Next Event: 3: Organizer
```

### 7. Enterprise Waste Audit Flow
```mermaid
flowchart TD
    subgraph "Admin Portal"
        A[Admin Login] --> B[2FA Verification]
        B --> C[Dashboard]
        C --> D[Start Audit]
    end
    
    subgraph "Mobile App"
        E[Bulk Scan Mode] --> F[Capture Items]
        F --> G[Auto-categorize]
        G --> H[Manual Review]
        H --> I[Submit Batch]
    end
    
    subgraph "Reporting"
        J[Generate Report] --> K[Compliance Check]
        K --> L[Export Options]
        L --> M[ERP Integration]
        L --> N[PDF Download]
        L --> O[Email Report]
    end
    
    D --> E
    I --> J
```

## Error Handling Patterns

### Network Error Flow
```mermaid
flowchart TD
    A[User Action] --> B[Network Request]
    B --> C{Network Available?}
    C -->|Yes| D[Process Request]
    C -->|No| E[Show Offline Banner]
    E --> F[Queue Action]
    F --> G[Store Locally]
    G --> H[Retry When Online]
    H --> D
    D --> I{Success?}
    I -->|Yes| J[Update UI]
    I -->|No| K[Show Error Message]
    K --> L[Retry Option]
    L --> B
```

### Permission Denied Flow
```mermaid
flowchart TD
    A[Feature Request] --> B{Permission Granted?}
    B -->|Yes| C[Execute Feature]
    B -->|No| D[Show Permission Dialog]
    D --> E{User Response}
    E -->|Allow| F[Grant Permission]
    E -->|Deny| G[Show Alternative Options]
    F --> C
    G --> H[Explain Benefits]
    H --> I[Settings Shortcut]
    I --> J[Manual Permission]
    J --> C
```

## Integration Patterns

### Third-Party Service Integration
```mermaid
sequenceDiagram
    participant A as App
    participant C as Cache
    participant S as Service
    participant F as Fallback
    
    A->>C: Check Cache
    alt Cache Hit
        C-->>A: Return Cached Data
    else Cache Miss
        A->>S: API Request
        alt Service Available
            S-->>A: Return Data
            A->>C: Update Cache
        else Service Down
            A->>F: Use Fallback
            F-->>A: Default Response
        end
    end
```

## Usage Guidelines

### When to Use Each Diagram Type

1. **Flowcharts**: Linear processes with decision points
2. **Sequence Diagrams**: Multi-actor interactions over time
3. **State Diagrams**: Complex state management
4. **Journey Maps**: User experience over time
5. **Graph Diagrams**: System architecture and relationships

### Best Practices

1. **Keep it Simple**: One flow per diagram
2. **Use Consistent Naming**: Standard terminology across flows
3. **Include Error States**: Show what happens when things go wrong
4. **Add Context**: Include relevant system boundaries
5. **Version Control**: Track changes to flow diagrams

### Diagram Maintenance

- Review diagrams monthly for accuracy
- Update when features change
- Link to implementation tickets
- Include in code review process
- Export as images for documentation

---

## Template Library

Copy and modify these templates for your specific flows:

### Basic User Action Flow
```mermaid
flowchart TD
    Start([User Opens App]) --> Action[User Takes Action]
    Action --> Process[System Processes]
    Process --> Result[Show Result]
    Result --> End([Flow Complete])
```

### Decision-Heavy Flow
```mermaid
flowchart TD
    A[Start] --> B{Condition 1}
    B -->|True| C{Condition 2}
    B -->|False| D[Alternative Path]
    C -->|True| E[Success Path]
    C -->|False| F[Fallback Path]
    D --> G[End State 1]
    E --> H[End State 2]
    F --> I[End State 3]
```

### Multi-Screen Flow
```mermaid
flowchart LR
    subgraph "Screen 1"
        A[Input] --> B[Validate]
    end
    subgraph "Screen 2"
        C[Process] --> D[Confirm]
    end
    subgraph "Screen 3"
        E[Result] --> F[Actions]
    end
    B --> C
    D --> E
```

Use these templates as starting points for documenting your specific user flows. 