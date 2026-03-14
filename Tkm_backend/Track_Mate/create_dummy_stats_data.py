#!/usr/bin/env python
"""
Script to generate realistic dummy trip data for the last month.
This creates sample trips with various modes of travel, distances, and costs
to populate the My Stats page with historical data.
"""

import os
import django
import random
from datetime import datetime, timedelta, time
from decimal import Decimal

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "trackmate.settings")
django.setup()

from auth_app.models import User
from trips.models import Trip
from django.utils import timezone

# Configuration for realistic data generation
MODES_OF_TRAVEL = ['car', 'bike', 'bus', 'metro', 'auto', 'walk', 'bike_taxi']
TRIP_PURPOSES = ['work', 'education', 'shopping', 'social', 'medical', 'personal', 'other']

# Realistic ranges for different transport modes
# Format: (min_distance, max_distance, min_cost, max_cost, min_co2_per_km, max_co2_per_km)
MODE_CONFIGS = {
    'car': (5, 50, 50, 500, 120, 180),          # g CO2/km: 120-180
    'bike': (3, 30, 150, 500, 5, 15),           # g CO2/km: 5-15 (low emission)
    'bus': (10, 80, 20, 100, 20, 40),           # g CO2/km: 20-40 (per person)
    'metro': (5, 40, 15, 60, 15, 30),           # g CO2/km: 15-30 (per person)
    'auto': (2, 25, 30, 150, 80, 120),          # g CO2/km: 80-120
    'walk': (1, 10, 0, 0, 0, 0),                # g CO2/km: 0
    'bike_taxi': (2, 20, 40, 120, 60, 100),     # g CO2/km: 60-100
}

LOCATION_PAIRS = [
    ('Home', 'Office'),
    ('Home', 'Shopping Mall'),
    ('Office', 'Coffee Shop'),
    ('Office', 'Restaurant'),
    ('Home', 'Gym'),
    ('Home', 'Park'),
    ('Home', 'Hospital'),
    ('Home', 'School'),
    ('Office', 'Meeting Room'),
    ('Office', 'Client Office'),
    ('Station', 'Office'),
    ('Station', 'Home'),
    ('Mall', 'Home'),
    ('Restaurant', 'Home'),
    ('Theater', 'Home'),
]

# Realistic location coordinates (example: Bangalore area)
LOCATION_COORDS = [
    (12.9352, 77.6245),  # Indiranagar
    (12.9716, 77.5946),  # Whitefield
    (13.0827, 80.2707),  # Chennai CBD
    (12.8384, 77.6408),  # Koramangala
    (13.1939, 77.5724),  # Sarjapur
    (12.9789, 77.7064),  # MG Road
    (13.0372, 77.5920),  # Electronic City
    (12.9352, 77.6384),  # Ulsoor
    (12.9698, 77.7499),  # Marathahalli
    (13.1956, 77.6245),  # Silk Board
]

def get_or_create_test_user():
    """Get or create test user for dummy data"""
    user, created = User.objects.get_or_create(
        email="test@example.com",
        defaults={
            "username": "testuser",
            "is_active": True,
            "is_verified": True,
        }
    )
    
    if created:
        user.set_password("test123456")
        user.save()
        print("✅ Created test user: test@example.com")
    else:
        print("✅ Using existing test user: test@example.com")
    
    return user

def generate_trip_data(user, date, trip_num):
    """Generate realistic trip data for a given date"""
    
    # Randomly select mode of travel
    mode = random.choice(MODES_OF_TRAVEL)
    config = MODE_CONFIGS[mode]
    min_dist, max_dist, min_cost, max_cost, min_co2, max_co2 = config
    
    # Generate trip details
    distance = Decimal(str(round(random.uniform(min_dist, max_dist), 2)))
    duration = int(float(distance) * random.uniform(2, 4))  # ~2-4 min per km
    
    # Generate cost (fuel expense or ticket cost)
    if mode == 'walk':
        fuel_cost = Decimal('0')
        ticket_cost = Decimal('0')
    elif mode in ['bus', 'metro', 'auto', 'bike_taxi']:
        ticket_cost = Decimal(str(round(random.uniform(min_cost, max_cost), 2)))
        fuel_cost = Decimal('0')
    else:  # car, bike
        fuel_cost = Decimal(str(round(random.uniform(min_cost, max_cost), 2)))
        ticket_cost = Decimal('0')
    
    # Generate CO2 emissions (g/km to kg conversion)
    co2_per_km = random.uniform(min_co2, max_co2)
    co2_emission = Decimal(str(round(float(distance) * co2_per_km / 1000, 2)))  # Convert to kg
    
    # Select random locations
    start_loc, end_loc = random.choice(LOCATION_PAIRS)
    start_coords = random.choice(LOCATION_COORDS)
    end_coords = random.choice(LOCATION_COORDS)
    
    # Generate random start time during the day (peak hours more likely)
    hour = random.choices(
        range(24),
        weights=[1, 1, 1, 1, 2, 5, 8, 10, 5, 3, 3, 3, 5, 4, 5, 8, 10, 8, 5, 3, 2, 1, 1, 1]
    )[0]
    minute = random.randint(0, 59)
    
    start_time = timezone.make_aware(
        datetime.combine(date, time(hour, minute))
    )
    end_time = start_time + timedelta(minutes=duration)
    
    # Additional costs
    toll_cost = Decimal(str(round(random.uniform(0, 50), 2))) if float(distance) > 15 else Decimal('0')
    parking_cost = Decimal(str(round(random.uniform(0, 30), 2))) if mode == 'car' and random.random() > 0.6 else Decimal('0')
    
    return {
        'user': user,
        'trip_number': f"TRIP-{date.strftime('%Y%m%d')}-{trip_num:03d}",
        'status': 'completed',
        'start_latitude': Decimal(str(start_coords[0])),
        'start_longitude': Decimal(str(start_coords[1])),
        'start_location_name': start_loc,
        'start_time': start_time,
        'end_latitude': Decimal(str(end_coords[0])),
        'end_longitude': Decimal(str(end_coords[1])),
        'end_location_name': end_loc,
        'end_time': end_time,
        'mode_of_travel': mode,
        'distance_km': distance,
        'duration_minutes': duration,
        'trip_purpose': random.choice(TRIP_PURPOSES),
        'number_of_companions': random.randint(0, 3),
        'ticket_cost': ticket_cost if ticket_cost > 0 else None,
        'fuel_expense': fuel_cost if fuel_cost > 0 else None,
        'toll_cost': toll_cost if toll_cost > 0 else None,
        'parking_cost': parking_cost if parking_cost > 0 else None,
        'co2_emission_kg': co2_emission,
        'is_manual_entry': True,
    }

def main():
    print("\n" + "="*70)
    print("GENERATING DUMMY STATS DATA FOR MY STATS PAGE")
    print("="*70 + "\n")
    
    # Step 1: Get or create test user
    print("📝 Step 1: Setting up test user...")
    user = get_or_create_test_user()
    print()
    
    # Step 2: Generate trips for last month
    print("🚗 Step 2: Generating trip data for the last 30 days...\n")
    
    today = timezone.now().date()
    thirty_days_ago = today - timedelta(days=30)
    
    trips_created = 0
    trips_skipped = 0
    
    for date in (thirty_days_ago + timedelta(n) for n in range(31)):
        # Generate 2-5 trips per day (realistic commute patterns)
        trips_per_day = random.randint(2, 5)
        
        for trip_num in range(1, trips_per_day + 1):
            try:
                trip_data = generate_trip_data(user, date, trip_num)
                
                # Check if trip already exists
                if not Trip.objects.filter(trip_number=trip_data['trip_number']).exists():
                    Trip.objects.create(**trip_data)
                    trips_created += 1
                else:
                    trips_skipped += 1
            except Exception as e:
                print(f"⚠️  Error creating trip for {date}: {str(e)}")
    
    print(f"✅ Dummy data generation complete!\n")
    print(f"📊 Summary:")
    print(f"   • Trips Created: {trips_created}")
    print(f"   • Trips Skipped (already exist): {trips_skipped}")
    print(f"   • Date Range: {thirty_days_ago} to {today}")
    print(f"   • User: test@example.com")
    print(f"\n💡 You can now view the My Stats page to see:")
    print(f"   • Daily scores and historical data")
    print(f"   • Distance, CO₂ emissions, and fuel cost graphs")
    print(f"   • Monthly calendar view with trip data")
    print(f"   • Statistics broken down by day/week/month")
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    main()
