# rails-8-avo

Rails 8.1.4.1 with PostgreSQL, Rodauth, Avo, Redis-backed Sidekiq, Vite, SCSS,
Turbo/Stimulus, and RSpec. The application namespace is `Rails8Avo`; models remain
top-level classes such as `User`, `Customer`, `Address`, `Product`, `SalesOrder`,
and `SalesOrderItem`. Avo provides the CRM UI; there is no separate custom frontend.

## Local development

Install the Ruby version in `.ruby-version` and Node 24, and start PostgreSQL and Redis:

```sh
bundle install
npm ci
bin/rails db:prepare
bin/dev
```

Rails runs at http://localhost:3000 and Vite at http://localhost:3036.
Avo (`/`) opens the customers resource. Verified users can manage shared CRM
records; users (`/resources/users`) and Sidekiq (`/sidekiq`) are admin-only.
User resource mutations and search endpoints also enforce this restriction.

The development seed creates the demonstration login `admin` / `admin`. Export
`ADMIN_PASSWORD` before the first seed to choose another password; production
requires it. Reseeding never resets an existing password or reopens a closed user.
Change demonstration credentials before allowing access outside your machine.

Public registration is disabled by default: an administrator creates staff users
through Avo. Set `ALLOW_PUBLIC_REGISTRATION=true` only if self-registration is
intentional: any registrant who verifies their email can access the shared CRM.
Explicit logout revokes the stored remember token as well as the browser cookie.

## Basic CRM and API

Customers have multiple addresses and sales orders. Products have unique SKUs and
nonnegative prices. Add order lines through Avo's association panel or the sales
order items resource. Each line stores its own unit price, defaulting to the product
price when created; later catalog price changes do not rewrite existing lines.
Totals use decimal arithmetic. This is a single-currency starting point without
inventory, taxes, invoicing, or payment processing. Customers/products referenced by
orders cannot be deleted; use product deactivation or order cancellation instead.

`GET /api/v1/health` is a public, non-cacheable JSON liveness endpoint:

```json
{"status":"ok","service":"rails-8-avo","api_version":"v1"}
```

`/up` remains available. Neither endpoint checks database or Redis readiness.
The API starts under `Api::V1`; CRM API CRUD/authentication are not exposed yet.
Webhooks and GraphQL are excluded. Existing accounts and authentication keys are
preserved by the migration to the ordinary `users` table.

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

Model, request and browser specs exercise real Rodauth routes, database records,
password hashing, delivered test emails, Avo forms, permissions, and order totals.
FactoryBot provides `build(:user)`, `create(:user, :admin)` and CRM factories.
The suite also checks eager loading and remember-cookie restoration/expiry/replay.
Test mail is never sent externally. CI builds the frontend and runs the full suite.

WebMock deliberately uses `allow_net_connect!(allow_localhost: true)`: real Ruby
HTTP calls are permitted and recorded, not blocked. Use `a_request` matchers to
assert them, or stub a specific third-party boundary when deterministic responses
are needed. WebMock does not intercept Chrome's own network traffic. The retry
integration spec uses a real localhost HTTP server, with no external credentials.
Do not configure tests with production API credentials.

## Exception handling

`HandleExceptionsService` preserves successful return values and re-raises failures
unless suppression is explicitly requested. It rescues `StandardError`, never
`Interrupt` or `SystemExit`. Retries are finite and limited to named error types:

```ruby
HandleExceptionsService.new(
  message: "Fetch remote status", max_tries: 3,
  retry_on: [Net::OpenTimeout, Net::ReadTimeout], wait: 0.1
).perform { client.fetch_status }
```

Only retry idempotent operations. `on_exception` and `before_retry` callbacks receive
`(exception, attempt_number)`; callback failures propagate. `skip_raise` accepts a
boolean or predicate, and `return_exception: true` returns failure context only when
suppression is enabled. Logs filter sensitive detail keys and omit raw exception
messages. `DetailedError` can attach structured details to a business failure.
No provider-specific APIs or sales-portal logging/database machinery are required.

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

A free Quick Tunnel needs no Cloudflare account or API token. Build frontend
assets first, and use a disposable demo database with a non-default admin password:

```sh
npm run build
cloudflared tunnel --url http://127.0.0.1:3000 --no-autoupdate
```

Copy the assigned `*.trycloudflare.com` hostname, then start (or restart) Rails:

```sh
PUBLIC_PREVIEW_HOST=your-assigned-host.trycloudflare.com bin/rails server -b 127.0.0.1 -p 3000
```

`PUBLIC_PREVIEW_HOST` allows that exact hostname, disables detailed development
error pages, uses built production frontend assets instead of the Vite development
filesystem proxy, and uses the HTTPS hostname for mailer links. Do not clear Rails'
host allowlist. Keep Rails and cloudflared running; the URL expires when the
tunnel stops and normally changes when restarted. This is not a production
deployment or an authentication boundary. Anyone with the URL can visit the app.
Stop the cloudflared process to revoke public access.
