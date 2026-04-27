from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import path
from graphene_django.views import GraphQLView
from apps.payments.views import stripe_webhook


def health(_: object) -> JsonResponse:
    return JsonResponse({'status': 'ok'})


urlpatterns = [
    path('admin/', admin.site.urls),
    path('healthz', health),
    path('graphql/', GraphQLView.as_view(graphiql=settings.DEBUG)),
    path('webhooks/stripe/', stripe_webhook),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
