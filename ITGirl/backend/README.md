# ITGirl Backend

Django + GraphQL backend for auth, routines, uploads, and payments.

## Local setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py runserver
```

## Docker setup

```bash
docker compose up --build
```
