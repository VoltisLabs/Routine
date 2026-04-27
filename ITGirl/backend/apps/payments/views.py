import json
import stripe
from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt

from apps.payments.models import CheckoutSession
from apps.routines.models import Routine, RoutineEntitlement
from apps.accounts.models import User

stripe.api_key = settings.__dict__.get('STRIPE_SECRET_KEY', '') or ''


@csrf_exempt
def stripe_webhook(request: HttpRequest) -> HttpResponse:
    payload = request.body
    sig = request.headers.get('Stripe-Signature')
    secret = settings.__dict__.get('STRIPE_WEBHOOK_SECRET', '') or ''

    try:
        if secret and sig:
            event = stripe.Webhook.construct_event(payload=payload, sig_header=sig, secret=secret)
        else:
            event = json.loads(payload.decode('utf-8'))
    except Exception:
        return HttpResponse(status=400)

    etype = event.get('type') if isinstance(event, dict) else event['type']
    data = event.get('data', {}).get('object', {}) if isinstance(event, dict) else event['data']['object']

    if etype == 'checkout.session.completed':
        session_id = data.get('id', '')
        routine_id = data.get('metadata', {}).get('routine_id')
        user_id = data.get('metadata', {}).get('user_id')
        checkout = CheckoutSession.objects.filter(stripe_session_id=session_id).first()
        if checkout:
            checkout.status = CheckoutSession.Status.COMPLETE
            checkout.save(update_fields=['status', 'updated_at'])
        if routine_id and user_id:
            user = User.objects.filter(pk=user_id).first()
            routine = Routine.objects.filter(pk=routine_id).first()
            if user and routine:
                RoutineEntitlement.objects.get_or_create(user=user, routine=routine)

    return JsonResponse({'received': True})
