from django.db import models

# Run scripts/flask_to_django.py to generate model skeletons from your SQLAlchemy models:
# python scripts/flask_to_django.py --source kerkoapp/models.py --out kerkoapp_dj/models.py
#
# The generated file will replace this placeholder. Review and fix relationships,
# field attributes, indexes, and constraints after generation.

class Placeholder(models.Model):
    # replace with generated models
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        abstract = True
