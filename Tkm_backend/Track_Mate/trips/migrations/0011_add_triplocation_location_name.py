# Generated migration to add location_name field to TripLocation model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('trips', '0010_alter_tripshare_unique_together_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='triplocation',
            name='location_name',
            field=models.CharField(blank=True, help_text='Reverse geocoded address for the location', max_length=500, null=True),
        ),
    ]
