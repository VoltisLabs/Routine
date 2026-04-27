import base64
import json
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import graphene
import stripe
from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.core.files.base import ContentFile
from django.core.signing import BadSignature, TimestampSigner
from django.utils.text import slugify
from graphene.types.generic import GenericScalar

from apps.payments.models import CheckoutSession
from apps.routines.models import Routine, RoutineEntitlement
from apps.uploads.models import UploadedProfileImage

User = get_user_model()
signer = TimestampSigner(salt='itgirl-auth')
stripe.api_key = settings.STRIPE_SECRET_KEY


class JSON(GenericScalar):
    class Meta:
        name = "JSON"


def _token_for(user_id: str, ttl_hours: int = 24) -> str:
    expiry = int((datetime.now(timezone.utc) + timedelta(hours=ttl_hours)).timestamp())
    raw = f'{user_id}:{expiry}:{secrets.token_urlsafe(12)}'
    return signer.sign(raw)


def _user_from_token(token: Optional[str]) -> Optional[User]:
    if not token:
        return None
    try:
        raw = signer.unsign(token, max_age=60 * 60 * 24 * 7)
        user_id, expiry, _ = raw.split(':', 2)
        if datetime.now(timezone.utc).timestamp() > int(expiry):
            return None
        return User.objects.filter(pk=user_id).first()
    except (BadSignature, ValueError):
        return None


def _auth_user(info) -> Optional[User]:
    header = info.context.headers.get('Authorization', '')
    token = header.replace('Bearer ', '').strip() if header.startswith('Bearer ') else None
    return _user_from_token(token)


class UserNode(graphene.ObjectType):
    id = graphene.ID(required=True)
    firstName = graphene.String(required=True)
    lastName = graphene.String()
    username = graphene.String(required=True)
    email = graphene.String()
    displayName = graphene.String()
    profilePictureUrl = graphene.String()


class LoginPayload(graphene.ObjectType):
    payload = JSON()
    refreshExpiresIn = graphene.Int()
    errors = JSON()
    success = graphene.Boolean()
    user = graphene.Field(UserNode)
    unarchiving = graphene.Boolean()
    use2fa = graphene.Boolean()
    useGoogleAuthenticator = graphene.Boolean()
    token = graphene.String(required=True)
    refreshToken = graphene.String(required=True)


class RegisterPayload(graphene.ObjectType):
    errors = JSON()
    success = graphene.Boolean()
    token = graphene.String()
    refreshToken = graphene.String()


class CheckoutSessionPayload(graphene.ObjectType):
    url = graphene.String()
    checkoutUrl = graphene.String()
    checkoutURL = graphene.String()


class SendSmsOtp(graphene.ObjectType):
    success = graphene.Boolean()


class Mutation(graphene.ObjectType):
    sendSmsOtp = graphene.Field(SendSmsOtp, action=graphene.String(), channel=graphene.String(), phoneNumber=graphene.String())
    login = graphene.Field(LoginPayload, email=graphene.String(), username=graphene.String(), password=graphene.String(required=True))
    register = graphene.Field(
        RegisterPayload,
        displayName=graphene.String(),
        email=graphene.String(required=True),
        username=graphene.String(required=True),
        firstName=graphene.String(required=True),
        lastName=graphene.String(required=True),
        password1=graphene.String(required=True),
        password2=graphene.String(required=True),
    )
    uploadProfilePhoto = graphene.Field(graphene.String, imageBase64=graphene.String(required=True))
    publishRoutine = graphene.Field(graphene.String, routine=JSON(required=True))
    itgirlSyncRoutine = graphene.Field(graphene.String, routineJson=graphene.String(required=True))
    createCheckoutSession = graphene.Field(
        CheckoutSessionPayload,
        routineId=graphene.ID(required=True),
        unlockPriceCredits=graphene.Int(required=True),
    )
    createStripeCheckoutSession = graphene.Field(
        CheckoutSessionPayload,
        routineId=graphene.ID(required=True),
        unlockPriceCredits=graphene.Int(required=True),
    )
    createCheckout = graphene.Field(
        CheckoutSessionPayload,
        routineId=graphene.ID(required=True),
        unlockPriceCredits=graphene.Int(required=True),
    )
    createStripeCheckout = graphene.Field(
        CheckoutSessionPayload,
        routineId=graphene.ID(required=True),
        unlockPriceCredits=graphene.Int(required=True),
    )
    verifyToken = graphene.Field(graphene.Boolean, token=graphene.String())
    refreshToken = graphene.Field(graphene.String, refreshToken=graphene.String())

    @staticmethod
    def resolve_sendSmsOtp(root, info, **kwargs):
        return SendSmsOtp(success=True)

    @staticmethod
    def resolve_login(root, info, password: str, email: Optional[str] = None, username: Optional[str] = None):
        user = None
        if email:
            user_obj = User.objects.filter(email__iexact=email).first()
            if user_obj:
                user = authenticate(info.context, username=user_obj.username, password=password)
        elif username:
            user = authenticate(info.context, username=username, password=password)

        if not user:
            return LoginPayload(
                success=False,
                errors={'message': 'Invalid credentials.'},
                token='',
                refreshToken='',
            )

        token = _token_for(str(user.id), ttl_hours=24)
        refresh_token = _token_for(str(user.id), ttl_hours=24 * 30)
        return LoginPayload(
            success=True,
            errors=None,
            token=token,
            refreshToken=refresh_token,
            refreshExpiresIn=60 * 60 * 24 * 30,
            user=UserNode(
                id=str(user.id),
                firstName=user.first_name or user.username,
                lastName=user.last_name,
                username=user.username,
                email=user.email,
                displayName=user.display_name or user.username,
                profilePictureUrl=user.profile_picture_url,
            ),
        )

    @staticmethod
    def resolve_register(root, info, **kwargs):
        email = kwargs.get('email', '').strip().lower()
        username = kwargs.get('username', '').strip()
        password1 = kwargs.get('password1', '')
        password2 = kwargs.get('password2', '')
        first_name = kwargs.get('firstName', '').strip()
        last_name = kwargs.get('lastName', '').strip()
        display_name = (kwargs.get('displayName') or '').strip()

        if password1 != password2:
            return RegisterPayload(success=False, errors={'message': 'Passwords do not match.'})
        if User.objects.filter(email__iexact=email).exists():
            return RegisterPayload(success=False, errors={'message': 'Email already registered.'})
        if User.objects.filter(username=username).exists():
            return RegisterPayload(success=False, errors={'message': 'Username already taken.'})

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password1,
            first_name=first_name,
            last_name=last_name,
            display_name=display_name,
        )
        return RegisterPayload(
            success=True,
            errors=None,
            token=_token_for(str(user.id), ttl_hours=24),
            refreshToken=_token_for(str(user.id), ttl_hours=24 * 30),
        )

    @staticmethod
    def resolve_uploadProfilePhoto(root, info, imageBase64: str):
        user = _auth_user(info)
        if not user:
            raise Exception('Authentication required.')

        raw = imageBase64.split(',', 1)[-1]
        binary = base64.b64decode(raw)
        filename = f'{slugify(user.username) or "user"}-{secrets.token_hex(4)}.jpg'
        upload = UploadedProfileImage.objects.create(user=user)
        upload.image.save(filename, ContentFile(binary), save=True)
        user.profile_picture_url = info.context.build_absolute_uri(upload.image.url)
        user.save(update_fields=['profile_picture_url'])
        return user.profile_picture_url

    @staticmethod
    def _upsert_routine(author: User, payload: dict[str, Any]) -> Routine:
        rid = payload.get('id')
        routine = Routine.objects.filter(id=rid).first() if rid else None
        if routine and routine.author_id != author.id:
            routine = None

        kind = payload.get('kind') or 'grwm'
        remote = payload.get('remoteCoverImageURLs') or []
        steps = payload.get('steps') or []
        unlock = int(payload.get('unlockPriceCredits') or 0)
        if unlock > 0 and unlock < 100:
            unlock = unlock * 100

        defaults = {
            'title': payload.get('title') or 'Untitled routine',
            'body': payload.get('body') or '',
            'kind': kind,
            'custom_kind_label': payload.get('customKindLabel') or '',
            'is_paywalled': bool(payload.get('isPaywalled') or False),
            'unlock_price_cents': max(0, unlock),
            'remote_cover_image_urls': remote,
            'steps': steps,
        }

        if routine:
            for key, value in defaults.items():
                setattr(routine, key, value)
            routine.save()
            return routine

        return Routine.objects.create(id=rid or None, author=author, **defaults)

    @staticmethod
    def resolve_publishRoutine(root, info, routine):
        user = _auth_user(info)
        if not user:
            # allow unauth dev writes into a local bot user
            user, _ = User.objects.get_or_create(username='itgirl-bot', defaults={'email': 'itgirl-bot@local.dev'})
        saved = Mutation._upsert_routine(user, routine or {})
        return str(saved.id)

    @staticmethod
    def resolve_itgirlSyncRoutine(root, info, routineJson: str):
        payload = json.loads(routineJson)
        return Mutation.resolve_publishRoutine(root, info, payload)

    @staticmethod
    def _create_checkout(user: User, routineId: str, unlockPriceCredits: int):
        routine = Routine.objects.filter(id=routineId).first()
        amount_cents = unlockPriceCredits if unlockPriceCredits >= 100 else unlockPriceCredits * 100
        if routine and routine.unlock_price_cents > 0:
            amount_cents = routine.unlock_price_cents
        amount_cents = max(100, amount_cents)
        routine_pk = routine.id if routine else routineId
        success_url = f"{settings.APP_BASE_URL}/checkout/success?session_id={{CHECKOUT_SESSION_ID}}"
        cancel_url = f"{settings.APP_BASE_URL}/checkout/cancel"
        metadata = {"user_id": str(user.id), "routine_id": str(routine_pk)}
        checkout_url = f"{settings.APP_BASE_URL}/mock-checkout/{secrets.token_urlsafe(16)}"
        stripe_session_id = ""

        if settings.STRIPE_SECRET_KEY:
            session = stripe.checkout.Session.create(
                mode="payment",
                success_url=success_url,
                cancel_url=cancel_url,
                metadata=metadata,
                line_items=[
                    {
                        "quantity": 1,
                        "price_data": {
                            "currency": "gbp",
                            "unit_amount": amount_cents,
                            "product_data": {
                                "name": (routine.title if routine else "Routine unlock"),
                                "description": "Unlock premium routine content",
                            },
                        },
                    }
                ],
            )
            checkout_url = session.url
            stripe_session_id = session.id

        checkout = CheckoutSession.objects.create(
            user=user,
            routine_id=routine_pk,
            amount_cents=amount_cents,
            checkout_url=checkout_url,
            stripe_session_id=stripe_session_id,
        )
        return CheckoutSessionPayload(
            url=checkout.checkout_url,
            checkoutUrl=checkout.checkout_url,
            checkoutURL=checkout.checkout_url,
        )

    @staticmethod
    def resolve_createCheckoutSession(root, info, routineId: str, unlockPriceCredits: int):
        user = _auth_user(info)
        if not user:
            raise Exception('Authentication required.')
        return Mutation._create_checkout(user, routineId, unlockPriceCredits)

    @staticmethod
    def resolve_createStripeCheckoutSession(root, info, routineId: str, unlockPriceCredits: int):
        return Mutation.resolve_createCheckoutSession(root, info, routineId, unlockPriceCredits)

    @staticmethod
    def resolve_createCheckout(root, info, routineId: str, unlockPriceCredits: int):
        return Mutation.resolve_createCheckoutSession(root, info, routineId, unlockPriceCredits)

    @staticmethod
    def resolve_createStripeCheckout(root, info, routineId: str, unlockPriceCredits: int):
        return Mutation.resolve_createCheckoutSession(root, info, routineId, unlockPriceCredits)

    @staticmethod
    def resolve_verifyToken(root, info, token: Optional[str] = None):
        return _user_from_token(token) is not None

    @staticmethod
    def resolve_refreshToken(root, info, refreshToken: Optional[str] = None):
        user = _user_from_token(refreshToken)
        if not user:
            return None
        return _token_for(str(user.id), ttl_hours=24)


class RoutineNode(graphene.ObjectType):
    id = graphene.ID(required=True)
    title = graphene.String(required=True)
    body = graphene.String(required=True)
    authorDisplayName = graphene.String(required=True)
    createdAt = graphene.DateTime(required=True)
    kind = graphene.String(required=True)
    customKindLabel = graphene.String()
    isPaywalled = graphene.Boolean(required=True)
    unlockPriceCredits = graphene.Int(required=True)
    remoteCoverImageURLs = graphene.List(graphene.String, required=True)
    steps = JSON()


class Query(graphene.ObjectType):
    ping = graphene.String(default_value='ok')
    routines = graphene.List(RoutineNode)
    me = graphene.Field(UserNode)
    hasRoutineAccess = graphene.Boolean(routineId=graphene.ID(required=True))

    @staticmethod
    def resolve_routines(root, info):
        out = []
        for r in Routine.objects.order_by('-created_at')[:200]:
            out.append(
                RoutineNode(
                    id=str(r.id),
                    title=r.title,
                    body=r.body,
                    authorDisplayName=r.author.resolved_display_name,
                    createdAt=r.created_at,
                    kind=r.kind,
                    customKindLabel=r.custom_kind_label,
                    isPaywalled=r.is_paywalled,
                    unlockPriceCredits=int((r.unlock_price_cents or 0) / 100) if r.unlock_price_cents else 0,
                    remoteCoverImageURLs=r.remote_cover_image_urls,
                    steps=r.steps,
                )
            )
        return out

    @staticmethod
    def resolve_me(root, info):
        user = _auth_user(info)
        if not user:
            return None
        return UserNode(
            id=str(user.id),
            firstName=user.first_name or user.username,
            lastName=user.last_name,
            username=user.username,
            email=user.email,
            displayName=user.display_name or user.username,
            profilePictureUrl=user.profile_picture_url,
        )

    @staticmethod
    def resolve_hasRoutineAccess(root, info, routineId: str):
        user = _auth_user(info)
        if not user:
            return False
        routine = Routine.objects.filter(id=routineId).first()
        if not routine:
            return False
        if routine.author_id == user.id:
            return True
        return RoutineEntitlement.objects.filter(user=user, routine=routine).exists()


schema = graphene.Schema(query=Query, mutation=Mutation)
