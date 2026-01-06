from django.urls import path
from . import views

urlpatterns = [
    # Add view stubs generated from Flask blueprints here.
    # Example:
    # path('', views.index, name='index'),
    path('bibliography/', include('kerkoapp_dj.bibliography_urls')),
]
