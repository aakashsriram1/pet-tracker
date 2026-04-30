# PawTrack

Mobile-first pet health tracker that helps owners manage medications, vaccinations, symptoms, diet, weight trends, reminders, and non-diagnostic AI health pattern flags.

PawTrack is a mobile-first pet health management app that gives pet owners one place to manage pet profiles, medication schedules, vaccination records, weight history, diet logs, symptoms, reminders, vet records, and nearby vet access. The AI layer does not diagnose. It only surfaces descriptive health patterns from logged data, such as weight changes, recurring symptoms, overdue vaccinations, or missed medication streaks.

## What PawTrack Does

- Manages multi-pet profiles with health history and owner notes
- Tracks medications, vaccination records, symptoms, diet, and weight trends
- Sends reminders for medication schedules, vaccinations, feeding, and vet visits
- Flags descriptive health patterns with strict non-diagnostic language
- Helps owners find nearby veterinary clinics through a vet locator map
- Exports pet health records for vet visits or personal record keeping
- Supports a freemium / Pro product model where advanced tracking and exports can be premium features

## Why This Project Matters

PawTrack combines mobile product engineering with health-adjacent AI guardrails. It requires thoughtful data modeling, notification workflows, retention-focused product design, privacy-conscious handling of pet health records, and clear separation between automated observations and licensed veterinary advice.

The project is built around a practical consumer workflow: owners need to remember what happened, when it happened, and what to ask their vet next. PawTrack keeps that workflow organized without presenting AI output as a medical diagnosis.

## Product Principles

- Mobile-first interface for quick logging and reminders
- Privacy-conscious handling of health-adjacent user data
- Clear separation between AI observations and veterinary advice
- Product language that avoids medical claims
- User retention through reminders, history, and recurring care routines

## Core Features

| Area | Feature |
| --- | --- |
| Profiles | Multi-pet profiles, age, breed, notes, and care history |
| Tracking | Medication, vaccinations, symptoms, diet, weight, and vet records |
| Reminders | Medication schedules, overdue vaccines, feeding, and appointments |
| AI pattern flags | Automated observations about trends, streaks, and changes in logged data |
| Vet access | Nearby vet locator and exportable records |
| Monetization | Freemium / Pro model for advanced history, exports, and premium reminders |

## AI Guardrails

PawTrack does not diagnose pets or replace licensed veterinary care. The AI layer only summarizes patterns already present in the owner's logged data, such as:

- Weight trending up or down over time
- Recurring symptoms appearing in recent logs
- Missed medication streaks
- Vaccinations or vet visits that appear overdue
- Changes in diet or appetite notes

Any health concern should be handled by a veterinarian. PawTrack's role is organization, reminders, and descriptive observations.

## Technical Focus

- Mobile-first product development
- Structured health-adjacent data modeling
- Notification and reminder systems
- AI-assisted pattern flagging with safety constraints
- Map-based vet discovery
- Exportable records for real-world user workflows
- Freemium product thinking and retention loops

## Example Tech Stack

| Layer | Tools |
| --- | --- |
| Mobile app | Flutter for iOS and Android |
| Backend | Supabase Auth, Postgres, and Storage |
| API / services | FastAPI for business logic and AI processing |
| Integrations | Maps, notifications, and optional AI provider APIs |

## Roadmap

- Build medication and vaccination reminder flows
- Add weight, diet, and symptom trend views
- Implement exportable pet health records
- Add vet locator map and clinic detail view
- Add non-diagnostic AI pattern flags
- Define Pro features around exports, advanced history, and multi-pet power users

## Resume Bullets

- Designed a mobile-first pet health management app covering multi-pet profiles, medications, vaccinations, symptoms, diet, weight trends, reminders, vet records, and nearby vet access.
- Added AI pattern-flagging concepts with strict non-diagnostic language, separating automated observations from licensed veterinary advice.
- Framed the product around retention-focused workflows, privacy-conscious health-adjacent data, notifications, exports, and a freemium / Pro business model.
