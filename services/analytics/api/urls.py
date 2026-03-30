from django.urls import path
from . import views

urlpatterns = [
    path("health/", views.health, name="health"),
    path("extract-features/", views.extract_features, name="extract_features"),
    path("score/", views.engagement_score, name="score"),
    path("ingest/", views.ingest, name="ingest"),
    path("insights/", views.insights, name="insights"),
    path("safety-alert/", views.safety_alert)
]