CREATE VIEW seat_map
WITH (security_invoker = true) AS
SELECT f.flight_id,
       f.flight_number,
       s.seat_id,
       s.seat_number,
       s.seat_row,
       s.seat_letter,
       s.seat_class,
       CASE WHEN b.seat_id IS NULL THEN 'AVAILABLE' ELSE 'BOOKED' END AS seat_status
FROM flight f
JOIN seat s
  ON s.aircraft_id = f.aircraft_id
LEFT JOIN booking b
  ON  b.flight_id = f.flight_id
  AND b.seat_id   = s.seat_id
  AND b.status    = 'CONFIRMED';

CREATE VIEW flight_availability
WITH (security_invoker = true) AS
SELECT f.flight_id,
       f.flight_number,
       o.city      AS from_city,
       o.iata_code AS from_code,
       d.city      AS to_city,
       d.iata_code AS to_code,
       f.departure_time,
       f.arrival_time,
       f.base_fare,
       f.status,
       COUNT(*)                                             AS total_seats,
       COUNT(*) FILTER (WHERE m.seat_status = 'BOOKED')     AS seats_booked,
       COUNT(*) FILTER (WHERE m.seat_status = 'AVAILABLE')  AS seats_available,
       ROUND(100.0 * COUNT(*) FILTER (WHERE m.seat_status = 'BOOKED') / COUNT(*), 1) AS load_factor_pct
FROM flight f
JOIN airport o  ON o.airport_id = f.origin_id
JOIN airport d  ON d.airport_id = f.destination_id
JOIN seat_map m ON m.flight_id  = f.flight_id
GROUP BY f.flight_id, o.city, o.iata_code, d.city, d.iata_code;
