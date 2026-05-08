# Heroku redeploy checklist

## Prerequisites

- Heroku CLI is installed and authenticated.
- The app is committed to a Git repository.
- Heroku Postgres and Cloudinary are available on the target Heroku app.

## Buildpacks

Use classic buildpacks in this order:

```bash
heroku buildpacks:clear --app <app-name>
heroku buildpacks:add heroku-community/apt --app <app-name>
heroku buildpacks:add heroku/nodejs --app <app-name>
heroku buildpacks:add heroku/ruby --app <app-name>
```

The Apt buildpack installs Japanese fonts and wkhtmltopdf from `Aptfile`.

## Required config vars

```bash
heroku config:set RAILS_ENV=production --app <app-name>
heroku config:set SECRET_KEY_BASE=$(bin/rails secret) --app <app-name>
```

Heroku Postgres sets `DATABASE_URL` automatically. Cloudinary add-on usually sets `CLOUDINARY_URL` automatically.

If Cloudinary is configured manually instead of using `CLOUDINARY_URL`, set:

```bash
heroku config:set CLOUDINARY_CLOUD_NAME=<cloud-name> --app <app-name>
heroku config:set CLOUDINARY_API_KEY=<api-key> --app <app-name>
heroku config:set CLOUDINARY_API_SECRET=<api-secret> --app <app-name>
```

Stripe checkout is optional. Set these only when using the checkout flow:

```bash
heroku config:set STRIPE_PUBLISHABLE_KEY=<publishable-key> --app <app-name>
heroku config:set STRIPE_SECRET_KEY=<secret-key> --app <app-name>
heroku config:set STRIPE_WEBHOOK_SECRET=<webhook-signing-secret> --app <app-name>
```

Register the Stripe webhook endpoint as:

```text
https://<app-name>.herokuapp.com/stripe/webhook
```

At minimum, subscribe to:

```text
checkout.session.completed
checkout.session.expired
```

## Deploy

```bash
git push heroku main
```

`Procfile` runs `bin/rails db:migrate` during the release phase.

For demo data:

```bash
heroku run bin/rails db:seed --app <app-name>
```

## Smoke checks

```bash
heroku run bin/rails runner "puts Rails.version" --app <app-name>
heroku run which wkhtmltopdf --app <app-name>
heroku open --app <app-name>
```

## Notes from local verification

- Ruby source files passed syntax checks.
- `app.json` parses as valid JSON.
- `config/storage.yml` and `config/cloudinary.yml` parse after ERB evaluation.
- Local `bundle install` on Windows can fail if MSYS2/libyaml is not initialized. Heroku builds on Linux and installs gems in a different environment, so use the Heroku build log as the deployment source of truth.

Initial login from the current seed data:

- Email: `admin@example.com`
- Password: `password1`
