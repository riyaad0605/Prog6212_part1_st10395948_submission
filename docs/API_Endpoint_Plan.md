# RaceDay - API Endpoint Plan

This document defines every RESTful API endpoint that the RaceDay system will expose. It was completed before any application code was written and serves as the contract between the planning phase (Part 1) and the implementation phase (Part 2).

---

## Authentication

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/auth/register | Registers a new user account with a specified role (Organiser or Participant). Hashes the password before storage. | None (public) | `{ "email": "string", "password": "string", "firstName": "string", "lastName": "string", "role": "Organiser \| Participant" }` | **201 Created** - returns userId and email. **409 Conflict** - email already registered. **400 Bad Request** - validation failed. |
| POST | /api/auth/login | Authenticates a user and returns a JWT token for subsequent requests. | None (public) | `{ "email": "string", "password": "string" }` | **200 OK** - returns JWT token and user role. **401 Unauthorized** - invalid credentials. |

## User Profile

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/users/profile | Retrieves the profile of the currently authenticated user based on their JWT token. | Any (logged in) | None | **200 OK** - returns user profile (userId, email, firstName, lastName, role, createdAt). **401 Unauthorized** - not logged in. |
| PUT | /api/users/profile | Updates the first name and last name of the currently authenticated user. | Any (logged in) | `{ "firstName": "string", "lastName": "string" }` | **200 OK** - returns updated profile. **400 Bad Request** - validation failed. **401 Unauthorized** - not logged in. |

## Events

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/events | Returns a list of all events. Participants use this to browse upcoming events. | Any (logged in) | None | **200 OK** - returns array of event objects with organiser name. |
| GET | /api/events/{id} | Returns the details of a single event by its ID, including its assigned categories. | Any (logged in) | None | **200 OK** - returns event object with categories. **404 Not Found** - event does not exist. |
| POST | /api/events | Creates a new event. The organiserId is set from the authenticated user's token. | Organiser | `{ "name": "string", "description": "string", "eventDate": "datetime", "location": "string" }` | **201 Created** - returns the new event object. **400 Bad Request** - validation failed. **403 Forbidden** - user is not an Organiser. |
| PUT | /api/events/{id} | Updates an existing event. Only the organiser who created it may update it. | Organiser | `{ "name": "string", "description": "string", "eventDate": "datetime", "location": "string", "status": "string" }` | **200 OK** - returns updated event. **403 Forbidden** - not the owning organiser. **404 Not Found** - event does not exist. |
| DELETE | /api/events/{id} | Deletes an event and its associated event-category links. Only the owning organiser may delete. | Organiser | None | **204 No Content** - event deleted. **403 Forbidden** - not the owning organiser. **404 Not Found** - event does not exist. |

## Categories

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/categories | Returns all available race categories (e.g. 5K, 10K, Half Marathon). | Any (logged in) | None | **200 OK** - returns array of category objects. |
| POST | /api/categories | Creates a new race category. | Organiser | `{ "name": "string", "description": "string", "distanceKm": number }` | **201 Created** - returns new category. **400 Bad Request** - validation failed. **409 Conflict** - category name already exists. |
| PUT | /api/categories/{id} | Updates an existing category. | Organiser | `{ "name": "string", "description": "string", "distanceKm": number }` | **200 OK** - returns updated category. **404 Not Found** - category does not exist. |
| DELETE | /api/categories/{id} | Deletes a category if it is not linked to any events. | Organiser | None | **204 No Content** - deleted. **404 Not Found** - does not exist. **409 Conflict** - category is in use by one or more events. |

## Event Categories (Linking Events to Categories)

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/events/{eventId}/categories | Assigns a category to a specific event with an optional participant cap. | Organiser | `{ "categoryId": number, "maxParticipants": number }` | **201 Created** - returns the event-category link. **404 Not Found** - event or category not found. **409 Conflict** - category already assigned to this event. |
| GET | /api/events/{eventId}/categories | Lists all categories assigned to a specific event. | Any (logged in) | None | **200 OK** - returns array of categories for the event with enrolment counts. |
| DELETE | /api/events/{eventId}/categories/{categoryId} | Removes a category from an event. Fails if participants are already enrolled. | Organiser | None | **204 No Content** - removed. **409 Conflict** - participants are enrolled in this category. |

## Event Enrolments

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/events/{eventId}/enrol | Enrols the authenticated participant in an event under a specific category. | Participant | `{ "categoryId": number }` | **201 Created** - returns enrolment record. **404 Not Found** - event or category not found. **409 Conflict** - already enrolled in this event. **400 Bad Request** - category is full (maxParticipants reached). |
| GET | /api/events/{eventId}/enrolments | Lists all enrolments for a given event. Organisers use this to view who has entered. | Organiser | None | **200 OK** - returns array of enrolment objects with participant names and categories. |
| GET | /api/enrolments/my | Returns all enrolments for the currently authenticated participant. Used for "My Events" view. | Participant | None | **200 OK** - returns array of the participant's enrolments with event and category details. |
| DELETE | /api/enrolments/{id} | Cancels an enrolment. Only the enrolled participant or the event organiser may cancel. | Participant or Organiser | None | **204 No Content** - enrolment cancelled. **404 Not Found** - enrolment does not exist. **403 Forbidden** - not authorised to cancel this enrolment. |

## Results

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/results | Captures a result for an enrolled participant. The organiser records finish time and position. | Organiser | `{ "enrolmentId": number, "finishTime": "HH:MM:SS", "position": number }` | **201 Created** - returns result record. **404 Not Found** - enrolment not found. **409 Conflict** - result already captured for this enrolment. |
| GET | /api/events/{eventId}/results | Returns all results for a specific event, grouped by category. | Any (logged in) | None | **200 OK** - returns array of results with participant names, categories, times, and positions. |
| GET | /api/results/my | Returns the performance history for the currently authenticated participant across all events. | Participant | None | **200 OK** - returns array of the participant's results with event names, dates, times, and positions. |
| PUT | /api/results/{id} | Updates a previously captured result. Only the event organiser may update. | Organiser | `{ "finishTime": "HH:MM:SS", "position": number }` | **200 OK** - returns updated result. **404 Not Found** - result not found. **403 Forbidden** - not authorised. |
