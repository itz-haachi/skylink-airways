SELECT o.iata_code || ' → ' || d.iata_code AS route,
       COUNT(b.booking_id)                 AS tickets_sold,
       SUM(b.price)                        AS revenue
FROM booking b
JOIN flight f  ON f.flight_id  = b.flight_id
JOIN airport o ON o.airport_id = f.origin_id
JOIN airport d ON d.airport_id = f.destination_id
WHERE b.status = 'CONFIRMED'
GROUP BY o.iata_code, d.iata_code
ORDER BY revenue DESC;

SELECT flight_number, from_city, to_city, departure_time,
       seats_booked, total_seats, load_factor_pct
FROM flight_availability
ORDER BY load_factor_pct DESC, departure_time
LIMIT 5;

SELECT flight_number, from_city, to_city, load_factor_pct
FROM flight_availability
WHERE load_factor_pct > (SELECT AVG(load_factor_pct) FROM flight_availability)
ORDER BY load_factor_pct DESC;

SELECT a.city,
       a.iata_code,
       COUNT(b.booking_id)         AS tickets_sold,
       COALESCE(SUM(b.price), 0)   AS revenue
FROM airport a
LEFT JOIN flight f  ON f.origin_id = a.airport_id
LEFT JOIN booking b ON b.flight_id = f.flight_id AND b.status = 'CONFIRMED'
GROUP BY a.airport_id, a.city, a.iata_code
ORDER BY revenue DESC;

SELECT s.seat_class,
       COUNT(*)                                            AS tickets,
       SUM(b.price)                                        AS revenue,
       ROUND(100.0 * SUM(b.price) / SUM(SUM(b.price)) OVER (), 1) AS pct_of_revenue
FROM booking b
JOIN seat s ON s.seat_id = b.seat_id
WHERE b.status = 'CONFIRMED'
GROUP BY s.seat_class;

SELECT f.flight_number,
       COUNT(*)                                        AS total_bookings,
       COUNT(*) FILTER (WHERE b.status = 'CANCELLED')  AS cancelled,
       ROUND(100.0 * COUNT(*) FILTER (WHERE b.status = 'CANCELLED')
             / NULLIF(COUNT(*), 0), 1)                 AS cancel_rate_pct
FROM booking b
JOIN flight f ON f.flight_id = b.flight_id
GROUP BY f.flight_number
HAVING COUNT(*) FILTER (WHERE b.status = 'CANCELLED') > 0
ORDER BY cancel_rate_pct DESC;

SELECT p.first_name || ' ' || p.last_name AS passenger,
       p.email,
       COUNT(*)      AS bookings,
       SUM(b.price)  AS total_spent
FROM passenger p
JOIN booking b ON b.passenger_id = p.passenger_id
WHERE b.status = 'CONFIRMED'
GROUP BY p.passenger_id, p.first_name, p.last_name, p.email
HAVING COUNT(*) > 1
ORDER BY bookings DESC, total_spent DESC;

SELECT ac.registration, m.model_name, ap.city AS based_at
FROM aircraft ac
JOIN aircraft_model m ON m.model_id   = ac.model_id
JOIN airport ap       ON ap.airport_id = ac.base_airport_id
WHERE NOT EXISTS (
  SELECT 1 FROM flight f WHERE f.aircraft_id = ac.aircraft_id
)
ORDER BY ap.city, ac.registration;
