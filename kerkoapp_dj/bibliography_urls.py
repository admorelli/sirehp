from django.urls import path
from . import bibliography_views as views

urlpatterns = [
    path('', views.index, name='bibliography_index'),
    # Add further routes here that map to converted blueprint endpoints.
    # Example: path('items/<int:id>/', views.item_detail, name='bibliography_item_detail'),
]
