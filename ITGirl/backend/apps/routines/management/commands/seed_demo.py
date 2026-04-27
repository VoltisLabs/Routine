from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.routines.models import Routine


class Command(BaseCommand):
    help = 'Seed demo routines for local/staging testing.'

    def handle(self, *args, **options):
        User = get_user_model()
        user, _ = User.objects.get_or_create(
            username='demo',
            defaults={
                'email': 'demo@itgirl.app',
                'display_name': 'Mara',
            },
        )
        if not user.has_usable_password():
            user.set_password('DemoPassword123!')
            user.save(update_fields=['password'])

        demos = [
            ('Paris Glow GRWM', 'grwm', False, 0),
            ('Date Night Routine', 'night', True, 900),
            ('Morning Reset', 'wellness', False, 0),
        ]
        created = 0
        for title, kind, paywalled, cents in demos:
            _, was_created = Routine.objects.get_or_create(
                title=title,
                author=user,
                defaults={
                    'body': f'{title} seeded routine',
                    'kind': kind,
                    'is_paywalled': paywalled,
                    'unlock_price_cents': cents,
                    'steps': [
                        {'title': 'Prep', 'detail': 'Cleanser and primer'},
                        {'title': 'Main look', 'detail': 'Core makeup routine'},
                        {'title': 'Finish', 'detail': 'Setting and accessories'},
                    ],
                },
            )
            created += int(was_created)

        self.stdout.write(self.style.SUCCESS(f'Seeded {created} routines (idempotent).'))
