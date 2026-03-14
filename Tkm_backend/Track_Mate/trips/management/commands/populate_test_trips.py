from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth import get_user_model
from trips.models import Trip

User = get_user_model()


class Command(BaseCommand):
    help = 'Populate test trip data in Indian context'

    def add_arguments(self, parser):
        parser.add_argument(
            '--user',
            type=str,
            help='Username to add trips for',
            default='testuser'
        )

    def handle(self, *args, **options):
        username = options['user']
        
        # Try to get or create the user
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': f'{username}@trackmate.com',
                'first_name': 'Test',
                'last_name': 'User'
            }
        )
        
        if created:
            user.set_password('testpassword123')
            user.save()
            self.stdout.write(self.style.SUCCESS(f'Created user: {username}'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Using existing user: {username}'))

        # Sample Indian trips data
        test_trips = [
            {
                'start_location_name': 'Delhi, India',
                'start_latitude': 28.6139,
                'start_longitude': 77.2090,
                'end_location_name': 'Gurgaon, Haryana',
                'end_latitude': 28.4595,
                'end_longitude': 77.0266,
                'mode_of_travel': 'car',
                'distance_km': 42.5,
                'duration_minutes': 65,
                'trip_purpose': 'work',
                'fuel_expense': 450.00,
                'toll_cost': 120.00,
                'parking_cost': 100.00,
                'co2_emission_kg': 5.1,
                'number_of_companions': 1,
                'status': 'completed',
                'days_ago': 5,
            },
            {
                'start_location_name': 'Bangalore, Karnataka',
                'start_latitude': 12.9716,
                'start_longitude': 77.5946,
                'end_location_name': 'WhiteField, Bangalore',
                'end_latitude': 13.0200,
                'end_longitude': 77.6458,
                'mode_of_travel': 'car',
                'distance_km': 28.3,
                'duration_minutes': 45,
                'trip_purpose': 'work',
                'fuel_expense': 350.00,
                'toll_cost': 0.00,
                'parking_cost': 80.00,
                'co2_emission_kg': 3.4,
                'number_of_companions': 2,
                'status': 'completed',
                'days_ago': 3,
            },
            {
                'start_location_name': 'Mumbai Central, Maharashtra',
                'start_latitude': 18.9676,
                'start_longitude': 72.8194,
                'end_location_name': 'Bandra, Mumbai',
                'end_latitude': 19.0596,
                'end_longitude': 72.8295,
                'mode_of_travel': 'auto',
                'distance_km': 18.5,
                'duration_minutes': 55,
                'trip_purpose': 'shopping',
                'ticket_cost': 380.00,
                'co2_emission_kg': 0.8,
                'number_of_companions': 0,
                'status': 'completed',
                'days_ago': 2,
            },
            {
                'start_location_name': 'Kolkata, West Bengal',
                'start_latitude': 22.5726,
                'start_longitude': 88.3639,
                'end_location_name': 'Salt Lake, Kolkata',
                'end_latitude': 22.5596,
                'end_longitude': 88.4397,
                'mode_of_travel': 'bike',
                'distance_km': 12.8,
                'duration_minutes': 35,
                'trip_purpose': 'education',
                'fuel_expense': 180.00,
                'parking_cost': 0.00,
                'co2_emission_kg': 0.0,
                'number_of_companions': 0,
                'status': 'completed',
                'days_ago': 7,
            },
            {
                'start_location_name': 'Hyderabad, Telangana',
                'start_latitude': 17.3850,
                'start_longitude': 78.4867,
                'end_location_name': 'HITECH City, Hyderabad',
                'end_latitude': 17.4426,
                'end_longitude': 78.4462,
                'mode_of_travel': 'car',
                'distance_km': 35.2,
                'duration_minutes': 50,
                'trip_purpose': 'work',
                'fuel_expense': 420.00,
                'toll_cost': 80.00,
                'parking_cost': 150.00,
                'co2_emission_kg': 4.2,
                'number_of_companions': 1,
                'status': 'completed',
                'days_ago': 1,
            },
            {
                'start_location_name': 'Chennai, Tamil Nadu',
                'start_latitude': 13.0827,
                'start_longitude': 80.2707,
                'end_location_name': 'Velachery, Chennai',
                'end_latitude': 12.9689,
                'end_longitude': 80.2241,
                'mode_of_travel': 'bus',
                'distance_km': 22.5,
                'duration_minutes': 60,
                'trip_purpose': 'medical',
                'ticket_cost': 85.00,
                'co2_emission_kg': 1.0,
                'number_of_companions': 0,
                'status': 'completed',
                'days_ago': 6,
            },
            {
                'start_location_name': 'Pune, Maharashtra',
                'start_latitude': 18.5204,
                'start_longitude': 73.8567,
                'end_location_name': 'Hinjewadi, Pune',
                'end_latitude': 18.5912,
                'end_longitude': 73.7499,
                'mode_of_travel': 'car',
                'distance_km': 31.5,
                'duration_minutes': 48,
                'trip_purpose': 'work',
                'fuel_expense': 380.00,
                'toll_cost': 0.00,
                'parking_cost': 120.00,
                'co2_emission_kg': 3.8,
                'number_of_companions': 1,
                'status': 'completed',
                'days_ago': 4,
            },
            {
                'start_location_name': 'Jaipur, Rajasthan',
                'start_latitude': 26.9124,
                'start_longitude': 75.7873,
                'end_location_name': 'City Palace, Jaipur',
                'end_latitude': 26.9240,
                'end_longitude': 75.8245,
                'mode_of_travel': 'auto',
                'distance_km': 8.5,
                'duration_minutes': 25,
                'trip_purpose': 'social',
                'ticket_cost': 150.00,
                'co2_emission_kg': 0.4,
                'number_of_companions': 2,
                'status': 'completed',
                'days_ago': 8,
            },
            {
                'start_location_name': 'Ahmedabad, Gujarat',
                'start_latitude': 23.0225,
                'start_longitude': 72.5714,
                'end_location_name': 'Vastrapur, Ahmedabad',
                'end_latitude': 23.1815,
                'end_longitude': 72.5533,
                'mode_of_travel': 'bike',
                'distance_km': 15.2,
                'duration_minutes': 40,
                'trip_purpose': 'shopping',
                'fuel_expense': 220.00,
                'parking_cost': 0.00,
                'co2_emission_kg': 0.0,
                'number_of_companions': 0,
                'status': 'completed',
                'days_ago': 9,
            },
            {
                'start_location_name': 'Indore, Madhya Pradesh',
                'start_latitude': 22.7196,
                'start_longitude': 75.8577,
                'end_location_name': 'Scheme No. 54, Indore',
                'end_latitude': 22.6639,
                'end_longitude': 75.8245,
                'mode_of_travel': 'car',
                'distance_km': 19.8,
                'duration_minutes': 35,
                'trip_purpose': 'education',
                'fuel_expense': 280.00,
                'parking_cost': 50.00,
                'co2_emission_kg': 2.4,
                'number_of_companions': 0,
                'status': 'completed',
                'days_ago': 10,
            },
        ]

        created_count = 0
        for trip_data in test_trips:
            days_ago = trip_data.pop('days_ago')
            start_time = timezone.now() - timedelta(days=days_ago, hours=9)
            
            # Calculate end time based on duration
            duration_minutes = trip_data.get('duration_minutes', 30)
            end_time = start_time + timedelta(minutes=duration_minutes)

            # Check if trip already exists
            existing = Trip.objects.filter(
                user=user,
                start_location_name=trip_data['start_location_name'],
                end_location_name=trip_data['end_location_name'],
                start_time__date=start_time.date(),
            ).exists()

            if not existing:
                trip = Trip.objects.create(
                    user=user,
                    start_time=start_time,
                    end_time=end_time,
                    **trip_data
                )
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f'✓ Created trip: {trip_data["start_location_name"]} → {trip_data["end_location_name"]}'
                    )
                )
            else:
                self.stdout.write(
                    self.style.WARNING(
                        f'⊘ Trip already exists: {trip_data["start_location_name"]} → {trip_data["end_location_name"]}'
                    )
                )

        self.stdout.write(
            self.style.SUCCESS(f'\n✓ Successfully created {created_count} test trips!')
        )
        self.stdout.write(
            self.style.SUCCESS(f'✓ All trips are for user: {username}')
        )
