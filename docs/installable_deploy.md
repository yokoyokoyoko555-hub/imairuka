# Installable deployment

This mode runs Imairuka as a single-company installation. It does not require Stripe Connect or multi-tenant setup.

## Requirements

- Docker Desktop
- A local copy of this repository

## 1. Prepare environment

Copy the sample env file:

```powershell
Copy-Item install.env.example install.env
```

For a quick local trial, the sample values are enough except Stripe. For production use, replace `SECRET_KEY_BASE` with a long random secret.

For Stripe direct payments, set:

```text
STRIPE_MODE=direct
STRIPE_PUBLISHABLE_KEY=pk_...
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

You can leave the Stripe values blank if you only want to test order, customer, product, and document management.

## 2. Start the app

```powershell
docker compose -f docker-compose.install.yml up -d --build
```

Open:

```text
http://localhost:3000
```

Initial login from seed data:

```text
admin@example.com
password1
```

## 3. Load sample data

The container prepares the database automatically. To load sample data:

```powershell
docker compose -f docker-compose.install.yml exec web ./bin/rails db:seed
```

## 4. Stripe webhook

If you expose this install to the internet, register this endpoint in Stripe:

```text
https://<your-domain>/stripe/webhook
```

For local webhook testing, use the Stripe CLI:

```powershell
stripe listen --forward-to localhost:3000/stripe/webhook
```

Then copy the displayed `whsec_...` value into `install.env` as `STRIPE_WEBHOOK_SECRET` and restart:

```powershell
docker compose -f docker-compose.install.yml restart web
```

Subscribe to:

```text
checkout.session.completed
checkout.session.expired
```

## 5. Stop

```powershell
docker compose -f docker-compose.install.yml down
```

To remove local data as well:

```powershell
docker compose -f docker-compose.install.yml down -v
```
