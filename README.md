# Portal

Rails 8.1.4.1 with PostgreSQL, Rodauth, Avo, Redis-backed Sidekiq, and RSpec.

## Local development

With Ruby, PostgreSQL, and Redis running:

```sh
bundle install
bin/rails db:prepare
bin/dev
```

Rails runs at http://localhost:3000. Avo (`/avo`) and Sidekiq (`/sidekiq`)
require an authenticated account with `admin: true`. Development emails are
written to `tmp/mails`, not delivered externally. See `.env.example` for settings;
export them in your shell (this app does not automatically load dotenv files).

```sh
bundle exec rspec
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman --no-pager
```

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
