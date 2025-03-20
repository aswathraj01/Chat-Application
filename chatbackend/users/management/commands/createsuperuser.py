from django.contrib.auth.management.commands import createsuperuser
from users.models import CustomUser

class Command(createsuperuser.Command):
    def handle(self, *args, **options):
        super().handle(*args, **options)
        # Set is_admin to True for the newly created superuser
        username = options.get('username')
        if username:
            user = CustomUser.objects.get(username=username)
            user.is_admin = True
            user.save()
            self.stdout.write(self.style.SUCCESS(f'Set is_admin=True for superuser "{username}"'))