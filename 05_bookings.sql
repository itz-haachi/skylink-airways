CREATE TABLE booking (
  booking_id    INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pnr           CHAR(6)       NOT NULL UNIQUE,
  passenger_id  INTEGER       NOT NULL REFERENCES passenger(passenger_id),
  flight_id     INTEGER       NOT NULL REFERENCES flight(flight_id),
  seat_id       INTEGER       NOT NULL REFERENCES seat(seat_id),
  price         NUMERIC(8,2)  NOT NULL,
  status        VARCHAR(10)   NOT NULL DEFAULT 'CONFIRMED',
  booked_at     TIMESTAMP     NOT NULL DEFAULT now(),
  cancelled_at  TIMESTAMP
);

CREATE UNIQUE INDEX one_booking_per_seat
ON booking (flight_id, seat_id)
WHERE status = 'CONFIRMED';

CREATE UNIQUE INDEX one_seat_per_passenger
ON booking (flight_id, passenger_id)
WHERE status = 'CONFIRMED';

CREATE OR REPLACE FUNCTION check_seat_on_flight()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM flight f
    JOIN seat s ON s.aircraft_id = f.aircraft_id
    WHERE f.flight_id = NEW.flight_id
      AND s.seat_id   = NEW.seat_id
  ) THEN
    RAISE EXCEPTION 'This seat is not on the aircraft operating this flight';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_seat
BEFORE INSERT OR UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION check_seat_on_flight();

INSERT INTO booking (pnr, passenger_id, flight_id, seat_id, price)
SELECT v.pnr, v.passenger_id, f.flight_id, s.seat_id,
       CASE WHEN s.seat_class = 'BUSINESS' THEN f.base_fare * 2.5
            ELSE f.base_fare END
FROM (VALUES
  ('K7M2QX', 1,  'SK101', '1A'),
  ('P4R9TZ', 2,  'SK101', '1B'),
  ('H3N8WC', 3,  'SK101', '12C'),
  ('B6Y2LM', 4,  'SK101', '12D'),
  ('Q9D4FS', 5,  'SK201', '3F'),
  ('T2X7KJ', 6,  'SK201', '4A'),
  ('M8C3VR', 7,  'SK301', '2B'),
  ('W5G6NP', 8,  'SK501', '5C'),
  ('Z3H9QB', 9,  'SK401', '7A'),
  ('R7L4DT', 10, 'SK601', '10D')
) AS v(pnr, passenger_id, flight_number, seat_number)
JOIN flight f ON f.flight_number = v.flight_number
JOIN seat s   ON s.aircraft_id   = f.aircraft_id
             AND s.seat_number   = v.seat_number;

UPDATE booking
SET status = 'CANCELLED', cancelled_at = now()
WHERE pnr = 'H3N8WC';
