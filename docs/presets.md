# Presets — DailySpark (MVP)

This document lists initial presets for Situation and Audience used by Generator and Training flows. Keep items light, safe, and broadly relatable.

## Situations (1-tap)
- Date: First coffee date
- Date: Dinner after a long break from dating
- Corporate: All-hands mixer
- Corporate: Cross-team lunch table
- Friends: House party small talk
- Family: Dinner with friends and kids
- Neighbors: Elevator/entrance chat
- Neighbors: Courtyard/park bench chat
- Travel: Airport lounge / train ride
- Events: Museum/gallery opening
- Fitness: Gym/fitness class pre/post
- Hobby: Book club first visit

## Audiences (1-tap)
- Work: Colleague from another department
- Work: New hire you just met
- Work: Manager from another team
- Date: Person returning to dating
- Date: Calm, thoughtful book-lover
- Friends: Friend-of-a-friend you’ve seen online
- Family/Friends: Couple with a toddler
- Neighbors: Elderly neighbor (polite, chatty)
- Neighbors: New young family next door
- Hobby: Amateur photographer
- Fitness: Casual runner / gym-goer
- Culture: Gallery-goer, curious about local events

## Notes & Style
- Positive, neutral, practical; avoid sensitive topics by default (see content_policy.md).
- Keep openings that invite personal stories, places, hobbies, and light observations.
- Encourage follow-ups that deepen without turning heavy.

## JSON Seed (for app seeding)
```json
{
  "situations": [
    {"id":"date_coffee_first","label":"Date — First coffee date","tags":["date","first_meet","casual"]},
    {"id":"date_dinner_return","label":"Date — Dinner after a long break","tags":["date","re-entry"]},
    {"id":"corp_all_hands","label":"Corporate — All-hands mixer","tags":["work","mixer"]},
    {"id":"corp_cross_team_lunch","label":"Corporate — Cross-team lunch","tags":["work","lunch"]},
    {"id":"friends_house_party","label":"Friends — House party small talk","tags":["friends","party"]},
    {"id":"family_dinner_with_friends","label":"Family — Dinner with friends and kids","tags":["family","dinner"]},
    {"id":"neighbors_elevator","label":"Neighbors — Elevator/entrance","tags":["neighbors","brief"]},
    {"id":"neighbors_courtyard","label":"Neighbors — Courtyard/park bench","tags":["neighbors","casual"]},
    {"id":"travel_lounge","label":"Travel — Airport lounge / train ride","tags":["travel","transit"]},
    {"id":"events_museum_opening","label":"Events — Museum/gallery opening","tags":["culture","event"]},
    {"id":"fitness_gym","label":"Fitness — Gym/fitness class","tags":["fitness","casual"]},
    {"id":"hobby_book_club","label":"Hobby — Book club first visit","tags":["hobby","reading"]}
  ],
  "audiences": [
    {"id":"work_cross_dept","label":"Work — Colleague from another department","tags":["work","peer"]},
    {"id":"work_new_hire","label":"Work — New hire you just met","tags":["work","new"]},
    {"id":"work_manager_other_team","label":"Work — Manager from another team","tags":["work","manager"]},
    {"id":"date_returning","label":"Date — Person returning to dating","tags":["date","re-entry"]},
    {"id":"date_book_lover","label":"Date — Thoughtful book-lover","tags":["date","reading"]},
    {"id":"friends_friend_of_friend","label":"Friends — Friend-of-a-friend online familiar","tags":["friends","social"]},
    {"id":"family_toddler_couple","label":"Family/Friends — Couple with a toddler","tags":["family","parents"]},
    {"id":"neighbor_elderly","label":"Neighbors — Elderly neighbor (polite, chatty)","tags":["neighbors","elder"]},
    {"id":"neighbor_young_family","label":"Neighbors — New young family next door","tags":["neighbors","family"]},
    {"id":"hobby_photographer","label":"Hobby — Amateur photographer","tags":["hobby","photo"]},
    {"id":"fitness_casual_runner","label":"Fitness — Casual runner / gym-goer","tags":["fitness","casual"]},
    {"id":"culture_gallery_goer","label":"Culture — Gallery-goer, local events","tags":["culture","events"]}
  ]
}
```

## Future Additions
- Localizable labels; region-aware variants (e.g., city-specific events).
- Per-preset tone notes (e.g., more playful vs. more formal).
- Link training scenarios to relevant presets for smoother onboarding.

