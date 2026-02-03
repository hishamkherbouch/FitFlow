# Exercise Database Setup

## 1) Create the table + RLS policies
1. Open Supabase SQL Editor.
2. Run `SUPABASE_EXERCISES.sql`.

## 2) Add secrets to `.env` (local only)
Add these keys (do not commit):

```
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
EXERCISE_SEED_SOURCE=api_ninjas
API_NINJAS_KEY=YOUR_API_NINJAS_KEY
EXERCISE_CACHE_PATH=data\exercises_api_ninjas.json
```

Notes:
- If you do not have an API Ninjas key, set `EXERCISE_SEED_SOURCE=wger`.
- ExerciseDB is still supported by setting `EXERCISE_SEED_SOURCE=exercisedb` and
  adding `EXERCISEDB_RAPIDAPI_KEY`.
- To seed from the saved API Ninjas cache, set `EXERCISE_SEED_SOURCE=api_ninjas_cache`.
- Service role key is required for seeding and should stay private.

## 3) Seed exercises into Supabase
Run:

```
.\scripts\seed_exercises.ps1
```

The script will:
- Use API Ninjas if `API_NINJAS_KEY` is present.
- Otherwise use Wger when `EXERCISE_SEED_SOURCE=wger`.
 - If `EXERCISE_SEED_SOURCE=api_ninjas_cache`, it will load from the local cache file.

## 4) Verify
Open the Supabase table editor for `exercises` and check that rows were created.
