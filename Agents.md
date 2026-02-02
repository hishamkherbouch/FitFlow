# AGENTS.md — Master Plan for FitFlow AI

## Project Overview
**App:** FitFlow AI
**Goal:** A unified iOS fitness and nutrition hub that replaces app-hopping between MyFitnessPal and Hevy with an integrated AI coach.
**Stack:** Flutter (iOS), Supabase (DB/Auth), Gemini Pro (AI Brain), Open Food Facts (Nutrition API).
**Current Phase:** Phase 1 — Foundation & Project Setup

## How I Should Think
1. **Understand Intent First**: Before answering, identify what the user actually needs.
2. **Ask If Unsure**: If critical information is missing, ask before proceeding.
3. **Plan Before Coding**: Propose a plan, ask for approval, then implement.
4. **Verify After Changes**: Run tests or manual checks after each change.
5. **Explain Trade-offs**: When recommending something, mention alternatives.

## Plan → Execute → Verify
1. **Plan:** Outline a brief approach and ask for approval before coding.
2. **Execute:** Implement one feature at a time.
3. **Verify:** Run manual checks or tests after each feature; fix before moving on.

## Context Files
Refer to these for details:
- `agent_docs/tech_stack.md`: Tech stack & libraries
- `agent_docs/project_brief.md`: Persistent rules and conventions
- `agent_docs/product_requirements.md`: Full PRD details
- `agent_docs/testing.md`: Verification strategy

## Roadmap
### Phase 1: Foundation
- [ ] Initialize Flutter iOS project
- [ ] Setup Supabase connection and Authentication
- [ ] Create basic app shell (Navigation Bar)

### Phase 2: Core Features
- [ ] Nutrition Tracker (Open Food Facts integration)
- [ ] Workout Logger (Templates & Exercise tracking)
- [ ] AI Coach (Gemini Pro context integration)

## What NOT To Do
- Do NOT delete files without explicit confirmation.
- Do NOT modify database schemas without a backup plan.
- Do NOT add features not in the current phase (e.g., Apple Watch sync).


## Windows Development Strategy
1. **Primary Platform:** Develop and debug using the **Android Emulator**.
2. **iOS Compatibility:** Keep code 100% Flutter-standard to ensure it compiles for iOS later.
3. **Build Pipeline:** Use **Codemagic CLI** or web interface for final iOS builds.