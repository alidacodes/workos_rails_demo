# Design Decisions & Tradeoffs

## App architecture

### Overview

A Rails 8.1 app demonstrating WorkOS SSO + Directory Sync with Okta. No database persistence; all identity data comes from WorkOS APIs, stored transiently in Rails sessions, cached server-side.

### Request Flow

```text
Browser
  │
  ├─ GET /           → PagesController#home       (public)
  │
  ├─ GET /login      → SessionsController#create  ──► WorkOS SSO authorization URL
  │                                                         │
  ├─ GET /auth/callback ◄────────────────────────────── OAuth callback
  │    └─ SessionsController#callback
  │         └─ WorkosApiAdapter#callback(code)
  │              ├─ exchange code for profile + token
  │              ├─ validate organization
  │              ├─ decode JWT → session[:expires_at]
  │              └─ store user info in Rails session
  │
  ├─ GET /directories     → DirectoriesController#index
  │    └─ WorkosApiAdapter#list_directories
  │
  └─ GET /directories/:id → DirectoriesController#show
       └─ WorkosApiAdapter#fetch_directory_user_list  (cursor-based pagination)
```

### File Structure

```text
workos_rails_demo/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb   # require_authentication, session expiry checks
│   │   ├── sessions_controller.rb      # SSO login / OAuth callback / logout
│   │   ├── directories_controller.rb   # Directory listing & user pagination
│   │   └── pages_controller.rb         # Public home page
│   ├── lib/
│   │   └── adapters/
│   │       └── workos_api_adapter.rb   # All WorkOS API calls (SSO + DirectorySync)
│   ├── views/
│   │   ├── pages/home.html.erb
│   │   ├── directories/
│   │   │   ├── index.html.erb          # List SCIM directories
│   │   │   └── show.html.erb           # Paginated users in a directory
│   │   └── layouts/
│   │       ├── application.html.erb
│   │       └── partials/               # _nav, _login_card, _logged_in_card, _flash
│   └── javascript/
│       └── controllers/                # Stimulus: mobile_menu, hide_on_click
├── config/
│   ├── routes.rb
│   └── initializers/
│       └── workos.rb                   # WorkOS SDK config (API key, 12s timeout)
├── db/                                 # SQLite present but schema is empty
├── docs/
│   └── design_decisions.md
├── .env.example                        # WORKOS_API_KEY, CLIENT_ID, ORG_ID, REDIRECT_URI
├── Dockerfile
└── Gemfile                             # workos ~> 6.1, Tailwind, Hotwire, Kamal
```

## Key Architectural Choices

### Framework choices

**Why build your own with Rails 8? Why not use one of the [Ruby example applications](https://github.com/workos/ruby-example-applications)?**

### Session-based authentication and defensive session management

**Why use session-based auth over storing tokens?**

- It reduces the need for client-side token management

**Why use server-side session storage via cache? And why manually set an `:expires_at` value if you already have an explicit TTL for the session stored in the cache?**

By storing sessions server-side, and only serving an opaque ID to the client, we avoid storing PII client-side, which would be an unnecessary risk (consider compliance, data minimization, cookie-based attacks) for little benefit when `solid_cache` is available to us. 

As for the manual `:expires_at` value alongside cache TTL, we're deliberately trading a bit of redundancy for improved user experience. We want to be able to serve a more explicit error if someone has been logged out of our app due to session expiry, rather than a generic message that anyone unauthenticated might see. As such, we deliberately set an `:expires_at` that's a bit more conservative than the cache's `expire_after` (60 minutes versus 70 minutes) so the soft check fires first, avoiding race conditions. It's a nice-to-have, but it makes a difference!

**Why #reset_session during the login process?**

It's a more defensive stance, but it prevents [session fixation attacks](https://owasp.org/www-community/attacks/Session_fixation) in the worst-case scenario. Also, session freshness!

### The WorkOS API Adapter

**Why the adapter? Why not integrate the API directly into the controllers?**

Adding an adapter layer between the WorkOS API and the controllers solves a few problems:

- Single-responsibility principle; the controllers are primarily meant to manage the presentation experience of the app. They control the flow, in concert with routing and views. Passing the API calls through an adapter layer to the controllers keeps them thin and focused on what they do best.
- Loose coupling; in keeping with single-responsibility principle, the controllers shouldn't care how interacting with the WorkOS API happens, just that they get consistent results. This also ensures that when changes are made to the WorkOS API, or we migrate services or APIs that we update the least amount of code possible. We can adapt different APIs into expected shapes for the app to consume.

### The Developer Experience

**Why the interactive `bin/start --<flag>` script, and not the default Rails setup flow?**

Perhaps for selfish reasons, but also to try and make onboarding as painless as possible! Especially for devs newer to Rails, it's nice to not have to remember the sequence of setting up an app locally for the first time. Plus, this way you're certain to have all of your needed environment variables available to you for the first run! Less friction, more building.

**Why `ENV.fetch` with no default value for all environment variables?**

If you don't have the values you need available to the app on initialization, it seems far kinder to me to fail fast, rather than initialize the full app and then getting confusing API errors at request time. This way, you get an explicit `KeyError (key not found: "<KEY>")` output during initialization so you can quickly address it and keep developing.

### View efficiency

**Why add pagination?**

The WorkOS API already supports cursor-based pagination; adding it for the Directory Users page (`directories#show`) ensures we're only grabbing the data we need, as we need it. Faster reads from the API, in exchange for an increased potential of hitting the rate limit; for a demo, this isn't a large concern, but it's good to think ahead slightly without over-engineering.

**Why pass the Directory name as a URL param to `directories#show`?**

Mostly, I'm avoiding a second API call for a display-only value; the list_users endpoint doesn't return the directory name, and get_directory would add latency for no functional benefit.
