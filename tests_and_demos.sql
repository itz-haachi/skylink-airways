UPDATE flight
SET departure_time = departure_time + make_interval(days => CURRENT_DATE + 1 - (SELECT MIN(departure_time)::date FROM flight)),
    arrival_time   = arrival_time   + make_interval(days => CURRENT_DATE + 1 - (SELECT MIN(departure_time)::date FROM flight));

SELECT f.flight_number, o.city AS from_city, d.city AS to_city,
       f.departure_time, f.base_fare
FROM flight f
JOIN airport o ON o.airport_id = f.origin_id
JOIN airport d ON d.airport_id = f.destination_id
ORDER BY f.departure_time;

INSERT INTO airport VALUES (6, 'BLR', 'Test', 'Test City');

INSERT INTO flight (flight_number, aircraft_id, origin_id, destination_id, departure_time, arrival_time, base_fare)
VALUES ('SK999', 12, 3, 3, CURRENT_DATE + 1 + TIME '08:00', CURRENT_DATE + 1 + TIME '09:00', 1000);

INSERT INTO flight (flight_number, aircraft_id, origin_id, destination_id, departure_time, arrival_time, base_fare)
VALUES ('SK998', 12, 3, 1, CURRENT_DATE + 1 + TIME '10:00', CURRENT_DATE + 1 + TIME '08:00', 1000);

INSERT INTO booking (pnr, passenger_id, flight_id, seat_id, price)
SELECT 'DUP001', 5, f.flight_id, s.seat_id, f.base_fare
FROM flight f JOIN seat s ON s.aircraft_id = f.aircraft_id
WHERE f.flight_number = 'SK101' AND s.seat_number = '1A';

INSERT INTO booking (pnr, passenger_id, flight_id, seat_id, price)
SELECT 'NEW12C', 5, f.flight_id, s.seat_id, f.base_fare
FROM flight f JOIN seat s ON s.aircraft_id = f.aircraft_id
WHERE f.flight_number = 'SK101' AND s.seat_number = '12C';

SELECT flight_number, from_city, to_city, seats_booked, seats_available, load_factor_pct
FROM flight_availability
ORDER BY departure_time;
