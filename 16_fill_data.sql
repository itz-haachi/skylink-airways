INSERT INTO passenger (first_name, last_name, email, phone, date_of_birth)
SELECT n.first_name,
       n.last_name,
       LOWER(n.first_name || '.' || n.last_name || g) || '@demo.skylink.in',
       '9' || LPAD((FLOOR(RANDOM() * 1e9))::BIGINT::TEXT, 9, '0'),
       DATE '1962-01-01' + FLOOR(RANDOM() * 15000)::INT
FROM generate_series(1, 300) AS g
CROSS JOIN LATERAL (
  SELECT (ARRAY['Aditi','Rohan','Kavya','Ishaan','Neha','Arnav','Pooja','Siddharth','Riya','Varun',
                'Tanvi','Kabir','Shreya','Aditya','Meghna','Nikhil','Lakshmi','Yash','Anjali','Dev'])[1 + g % 20]               AS first_name,
         (ARRAY['Patel','Kumar','Rao','Chatterjee','Mehta','Pillai','Joshi','Kapoor','Banerjee','Naidu',
                'Verma','Shetty','Saxena','Ghosh','Kulkarni','Bhat','Malhotra','Sinha','Hegde','Roy'])[1 + (g / 20 + 3 * g) % 20] AS last_name
) AS n
ON CONFLICT (email) DO NOTHING;

WITH
flights AS (
  SELECT f.flight_id, f.flight_number, f.aircraft_id, f.base_fare,
         COUNT(*) AS total_seats,
         (SELECT COUNT(*) FROM booking b
          WHERE b.flight_id = f.flight_id AND b.status = 'CONFIRMED') AS booked,
         (ARRAY[0.42, 0.24, 0.35, 0.18, 0.31, 0.27, 0.38, 0.22, 0.33, 0.29, 0.26, 0.35])[(f.flight_id - 1) % 12 + 1] AS target_pct,
         (ARRAY[0.06, 0.15, 0.10, 0.22, 0.08, 0.12, 0.04, 0.18, 0.10, 0.14, 0.07, 0.16])[(f.flight_id - 1) % 12 + 1] AS cancel_share
  FROM flight f
  JOIN seat s ON s.aircraft_id = f.aircraft_id
  GROUP BY f.flight_id
),
to_add AS (
  SELECT *, GREATEST(0, ROUND(total_seats * target_pct) - booked)::INT AS n
  FROM flights
),
free_seats AS (
  SELECT t.flight_id, t.base_fare, t.n, t.cancel_share, s.seat_id, s.seat_class,
         ROW_NUMBER() OVER (PARTITION BY t.flight_id ORDER BY RANDOM()) AS rn
  FROM to_add t
  JOIN seat s ON s.aircraft_id = t.aircraft_id
  WHERE NOT EXISTS (SELECT 1 FROM booking b
                    WHERE b.flight_id = t.flight_id AND b.seat_id = s.seat_id
                      AND b.status = 'CONFIRMED')
    AND (t.flight_number, s.seat_number) NOT IN (('SK102','20C'), ('SK102','21C'), ('SK101','12C'))
),
people AS (
  SELECT passenger_id,
         ROW_NUMBER() OVER (ORDER BY passenger_id) AS pn,
         COUNT(*) OVER () AS total
  FROM passenger
  WHERE email LIKE '%@demo.skylink.in'
),
chosen AS (
  SELECT fs.*,
         CASE WHEN fs.rn <= fs.n THEN 'CONFIRMED' ELSE 'CANCELLED' END AS status,
         now() - (RANDOM() * INTERVAL '20 days') - INTERVAL '1 hour' AS booked_at,
         p.passenger_id
  FROM free_seats fs
  JOIN people p ON p.pn = (fs.rn + fs.flight_id * 53) % p.total + 1
  WHERE fs.rn <= fs.n + CEIL(fs.n * fs.cancel_share)
)
INSERT INTO booking (pnr, passenger_id, flight_id, seat_id, price, status, booked_at, cancelled_at)
SELECT
  (SELECT STRING_AGG(SUBSTR('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + FLOOR(RANDOM() * 32)::INT, 1), '')
   FROM generate_series(1, 6) WHERE c.seat_id IS NOT NULL),
  c.passenger_id,
  c.flight_id,
  c.seat_id,
  CASE WHEN c.seat_class = 'BUSINESS' THEN c.base_fare * 2.5 ELSE c.base_fare END,
  c.status,
  c.booked_at,
  CASE WHEN c.status = 'CANCELLED'
       THEN c.booked_at + RANDOM() * (now() - c.booked_at) END
FROM chosen c
ON CONFLICT DO NOTHING;

SELECT flight_number, seats_booked, total_seats, load_factor_pct
FROM flight_availability
ORDER BY flight_number;
