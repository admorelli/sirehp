# Flask -> Django migration scaffold (django-migration branch)

What this adds
- A minimal Django project scaffold under `sirehp_dj/`.
- A Django app `kerkoapp_dj/` with placeholders.
- A helper script `scripts/flask_to_django.py` to generate Django model skeletons from SQLAlchemy models (best-effort).
- Minimal requirements suggestion file (see below) and migration notes.

Important notes
- This is a best-effort, semi-automated scaffold. A complete automatic conversion is not generally possible.
- You MUST manually review and fix:
  - Generated Django models (relationships, unique/nullable constraints, indexes).
  - Templates (Jinja -> Django template syntax).
  - Blueprints -> views and URL patterns.
  - Extension replacements (Flask-Login, Flask-Mail, config handling).
  - Celery and background jobs wiring.
  - Docker / deployment config and environment variables.

How to generate models from your SQLAlchemy models
1. Ensure you have Python and dependencies installed (see below).
2. Run:
   ```
   python scripts/flask_to_django.py --source kerkoapp/models.py --out kerkoapp_dj/models.py
   ```
3. Inspect and edit `kerkoapp_dj/models.py` carefully.

Suggested requirements
- Add Django to your environment. Example entry:
  - `Django>=4.2,<5`
- Keep SQLAlchemy installed if you still need it for transitional work.

How to run locally (quick)
1. Checkout branch `django-migration`.
2. Create a virtualenv and install Django:
   ```
   python -m venv .venv
   source .venv/bin/activate
   pip install "Django>=4.2,<5"
   ```
3. Make migrations and migrate:
   ```
   cd sirehp_dj
   python manage.py makemigrations
   python manage.py migrate
   python manage.py runserver
   ```

Next manual tasks (high level)
- Run the model-generation script and fix models.
- Convert Flask views and blueprints to Django views and urls.
- Replace Flask-specific extensions with Django equivalents.
- Add tests and ensure functionality parity.

If you want me to push
- Grant permission for me to push commits to the `django-migration` branch and I will commit these files and open a draft PR that documents what was automated and what needs manual follow-up
