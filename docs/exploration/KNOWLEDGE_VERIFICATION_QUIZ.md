# Knowledge Verification / Quiz Loop

**Purpose**: Explore how quizzes verify user learning, not just activity, and how they integrate with gamification, corrections, and education.
**Status**: Exploration — `quiz_screen.dart` exists; no systematic design
**Last Updated**: 2026-05-25
**Related**: [AI_GENERATED_EDUCATIONAL_CONTENT.md](AI_GENERATED_EDUCATIONAL_CONTENT.md), [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md)

---

## Problem Statement

The app currently rewards scanning (volume) but doesn't verify that the user *learned* anything. Two design failures:

1. **Volume ≠ Understanding**: A user can scan 100 items and learn nothing about waste sorting
2. **No feedback loop for education**: The app doesn't know what the user knows, so it can't target education

Quizzes are the only mechanism that verifies learning, not just activity.

---

## Research Summary

### Learning vs Activity Verification

| Pattern | Reward Focus | Outcome |
|---------|-------------|---------|
| Volume-only (current) | Items scanned | High DAU, shallow learning |
| Streak-based | Daily logins | Good retention, no verification |
| Quiz-verified | Correct answers | Verified knowledge, deeper engagement |

### Adaptive Difficulty from Correction History

- Pull quiz questions from the user's own correction history (items they got wrong → quiz them)
- Use spaced repetition: quiz on corrected items after 1 day, 3 days, 7 days, 30 days
- If user consistently answers correctly about "plastic bottles", graduate them; if they keep getting "hazardous waste" wrong, surface more education

### Reward Asymmetry — Mastery > Volume

| Action | Points | Why |
|--------|--------|-----|
| Scan item (volume) | 10 | Base reward for participation |
| Correct identification | 5 | User got it right |
| Quiz correct answer | 25 | Verified understanding (3x volume) |
| Quiz streak (5+ correct) | 50 bonus | Reinforcement |
| Teach someone else | 100 | Highest form of learning |

### Content Sources

Hybrid model recommended:
- **AI-generated**: Adaptive quizzes from user's history (cheap per-quiz, high personalization)
- **Curated**: Core curriculum on safety-critical categories (hazardous, sharps, batteries — accuracy needed)
- **Correction-sourced**: Quiz items drawn from items the user has corrected in the past

---

## Quiz Design

### Quiz Types

| Type | Trigger | Frequency | Reward |
|------|---------|-----------|--------|
| **Quick check** | After scan result | Optional, 1 question | 5 bonus points |
| **Daily challenge** | Daily reset | 3 questions | 50 points + badge |
| **Safety mastery** | After hazardous item scan | 5 questions | Exclusive badge |
| **Weekly review** | Sunday | 10 questions from week's history | 200 points |
| **Correction pop-quiz** | 24h after correction | 1 question (spaced repetition) | 25 points |

### UI Design

- **Low friction**: 1-2 tap answers (multiple choice, not open-ended)
- **Contextual timing**: After a scan result, offer "Quick Quiz: What bin does this go in?"
- **Progress visibility**: Show quiz mastery as a separate stat (not conflated with scan count)
- **Failure handling**: Wrong answer → show education card, don't punish (points never decrease)

---

## Key Decisions Needed

1. **Mandatory vs optional**: Should quizzes be optional (learning enhancement) or required for certain unlocks (premium features, advanced challenges)?
2. **Quiz content generation**: AI-generated from user history vs curated curriculum vs hybrid?
3. **Classroom mode**: School/teacher use requires quiz assignments, grades, progress dashboards
4. **Reward asymmetry ratio**: How much more should mastery be worth than volume? (Current hypothesis: 3x)

---

## Open Questions

- Do quizzes reduce scan volume by competing for the same attention budget?
- What's the right quiz frequency before it feels like homework?
- Should quiz results affect the AI training dataset (correct answers = implicit training signal)?
- How do we prevent quiz farming (spamming quizzes for points)?

---

## Next Steps

1. Design quiz type taxonomy and trigger conditions
2. Implement correction-sourced quiz generator (pull from user's correction history)
3. A/B test quiz reward asymmetry (volume-only vs quiz-enhanced)
4. Build quiz mastery dashboard
