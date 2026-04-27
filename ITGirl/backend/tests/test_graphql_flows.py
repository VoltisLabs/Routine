import base64
import json
from unittest.mock import patch
from typing import Optional

from django.test import TestCase


class GraphQLFlowTests(TestCase):
    endpoint = '/graphql/'

    def gql(self, query: str, variables: Optional[dict] = None, token: Optional[str] = None):
        body = {'query': query, 'variables': variables or {}}
        headers = {}
        if token:
            headers['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        response = self.client.post(self.endpoint, data=json.dumps(body), content_type='application/json', **headers)
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        if payload.get('errors'):
            self.fail(str(payload['errors']))
        return payload['data']

    def test_register_login_publish_checkout_access(self):
        register = self.gql(
            """
            mutation Register($email: String!, $username: String!, $first: String!, $last: String!, $p1: String!, $p2: String!, $displayName: String!) {
              register(email: $email, username: $username, firstName: $first, lastName: $last, password1: $p1, password2: $p2, displayName: $displayName) {
                success
                token
                refreshToken
              }
            }
            """,
            {
                'email': 'test@itgirl.app',
                'username': 'testuser',
                'first': 'Test',
                'last': 'User',
                'p1': 'Password123!',
                'p2': 'Password123!',
                'displayName': 'Test User',
            },
        )
        self.assertTrue(register['register']['success'])
        token = register['register']['token']
        login = self.gql(
            """
            mutation Login($email: String!, $password: String!) {
              login(email: $email, password: $password) {
                success
                token
                refreshToken
                user { username }
              }
            }
            """,
            {"email": "test@itgirl.app", "password": "Password123!"},
        )
        self.assertTrue(login["login"]["success"])
        token = login["login"]["token"]

        publish = self.gql(
            """
            mutation Publish($routine: JSON!) {
              publishRoutine(routine: $routine)
            }
            """,
            {
                'routine': {
                    'title': 'Night Routine',
                    'body': 'Step 1',
                    'kind': 'grwm',
                    'isPaywalled': True,
                    'unlockPriceCredits': 900,
                    'steps': [{'title': 'A', 'instructions': 'B'}],
                }
            },
            token=token,
        )
        routine_id = publish['publishRoutine']

        with patch('apps.api.schema.settings.STRIPE_SECRET_KEY', ''), patch('apps.api.schema.settings.APP_BASE_URL', 'http://localhost:8000'):
            checkout = self.gql(
                """
                mutation Checkout($routineId: ID!, $unlockPriceCredits: Int!) {
                  createCheckoutSession(routineId: $routineId, unlockPriceCredits: $unlockPriceCredits) {
                    checkoutURL
                  }
                }
                """,
                {'routineId': routine_id, 'unlockPriceCredits': 900},
                token=token,
            )
        self.assertIn('mock-checkout', checkout['createCheckoutSession']['checkoutURL'])

        me = self.gql('query { me { username displayName } }', token=token)
        self.assertEqual(me['me']['username'], 'testuser')

    def test_upload_profile_photo(self):
        reg = self.gql(
            """
            mutation {
              register(email: "photo@itgirl.app", username: "photo", firstName: "Photo", lastName: "User", password1: "Password123!", password2: "Password123!", displayName: "Photo User") {
                token
                success
              }
            }
            """
        )
        token = reg['register']['token']
        sample = base64.b64encode(b'not-a-real-jpeg-but-good-enough').decode('utf-8')
        out = self.gql(
            'mutation Upload($imageBase64: String!) { uploadProfilePhoto(imageBase64: $imageBase64) }',
            {'imageBase64': sample},
            token=token,
        )
        self.assertIn('/media/profile-photos/', out['uploadProfilePhoto'])
