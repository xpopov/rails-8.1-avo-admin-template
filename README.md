# rails-8-avo

Rails 8.1.4.1 with PostgreSQL, Rodauth, Avo, Redis-backed Sidekiq, Vite, SCSS,
Turbo/Stimulus, and RSpec. The application namespace is `Rails8Avo`; models remain
top-level classes such as `Account`.

## Local development

Install the Ruby version in `.ruby-version` and Node 24, and start PostgreSQL and Redis:

```sh
bundle install
npm ci
bin/rails db:prepare
bin/dev
```

Rails runs at http://localhost:3000 and Vite at http://localhost:3036.
Avo (`/`, with accounts at `/resources/accounts`) and Sidekiq (`/sidekiq`)
require an authenticated account with `admin: true`. The initial database seed
creates the demonstration login `admin` / `admin`; change its password before
allowing access from outside your development machine.

Development emails are written to `tmp/mails`, not delivered externally.
See `.env.example` for settings; export them in your shell. Rails does not
automatically load this file. Never put credentials in frontend environment variables.

## Frontend assets

Application assets live in `app/frontend`. The JavaScript entrypoint imports
SCSS and automatically registers Stimulus controllers. Vite handles imported
images/fonts and stylesheet `url(...)` references; use `vite_image_tag` for
images under `app/frontend/images` referenced from Rails views.

`bin/dev` runs Rails, Sidekiq, and Vite. Styles and Stimulus controllers use HMR;
changes to ERB views, helpers, and routes trigger a browser reload. Avo keeps its
own assets through Propshaft. Production `bin/rails assets:precompile` builds
both asset pipelines, and the Docker build installs Node only in the build stage.

## Tests

Install Chrome or Chromium for the headless Capybara system specs. Selenium
can manage the matching driver; an installed ChromeDriver on `PATH` also works.
Set `CHROME_BIN` if the browser is not discovered automatically. Only in a trusted
container that cannot support Chrome's sandbox, set `CHROME_NO_SANDBOX=1`.
Failure screenshots are saved under `tmp/capybara`.

```sh
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
bundle exec rspec spec/requests
bundle exec rspec spec/system
bin/rubocop
RAILS_ENV=test bin/rails zeitwerk:check
bin/brakeman --no-pager
```

Request and browser specs exercise real Rodauth routes, database records,
password hashing, and verification/reset links from delivered test emails.
Test mail is never sent externally. CI installs frontend dependencies, runs
request and browser specs, and checks production asset compilation.

## Deferred security blocker

**Status: postponed at the user's request; not resolved.** Brakeman 8.1.1 flags
Ruby 3.3.11 for critical remote code execution advisory **CVE-2026-132825** and
recommends Ruby **3.3.14 or later**. The security scan / security CI remains failing.

Before production deployment, upgrade the runtime and `.ruby-version`, verify
the Docker Ruby version, reinstall dependencies as necessary, and rerun the
specs, eager-loading check, lint, and Brakeman. The runtime has not been upgraded
or the finding suppressed. Any public preview is temporary and must not contain
real credentials, customer data, or production integrations.

## Temporary Cloudflare preview

A free Quick Tunnel needs no Cloudflare account or API token:

```sh
cloudflared tunnel --url http://127.0.0.1:3000 --no-autoupdate
```

Copy the assigned `*.trycloudflare.com` hostname, then start (or restart) Rails:

```sh
PUBLIC_PREVIEW_HOST=your-assigned-host.trycloudflare.com bin/rails server -b 127.0.0.1 -p 3000
```

`PUBLIC_PREVIEW_HOST` allows that exact hostname, disables detailed development
error pages, and uses the HTTPS hostname for mailer links. Do not clear Rails'
host allowlist. Keep Rails and cloudflared running; the URL expires when the
tunnel stops and normally changes when restarted. This is not a production
deployment or an authentication boundary. Anyone with the URL can visit the app.
Stop the cloudflared process to revoke public access.
