# Deployment (Prelura-style baseline)

## Environments

- `dev`: local Docker + postgres
- `staging`: cloud app + managed postgres + Stripe test keys
- `prod`: cloud app + managed postgres + Stripe live keys

## Required env vars

- `DJANGO_SECRET_KEY`
- `DJANGO_DEBUG`
- `DJANGO_ALLOWED_HOSTS`
- `DB_ENGINE`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `APP_BASE_URL`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

## Build and release commands

- Build: `pip install -r requirements.txt`
- Release: `python manage.py migrate && python manage.py seed_demo`
- Run: `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT`

## Webhook setup

- Configure Stripe webhook to: `https://<env-domain>/webhooks/stripe/`
- Listen for event: `checkout.session.completed`
- Use env-specific webhook signing secret in `STRIPE_WEBHOOK_SECRET`
