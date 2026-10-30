ALTER TABLE passenger
  ADD COLUMN user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION book_seat(
  p_flight_id    INTEGER,
  p_seat_number  VARCHAR,
  p_first_name   VARCHAR,
  p_last_name    VARCHAR,
  p_email        VARCHAR,
  p_phone        VARCHAR DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_flight      flight%ROWTYPE;
  v_seat        seat%ROWTYPE;
  v_passenger   INTEGER;
  v_price       NUMERIC(8,2);
  v_pnr         TEXT;
  v_chars       TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_constraint  TEXT;
  v_uid         UUID := auth.uid();
  v_email       TEXT;
BEGIN
  SELECT * INTO v_flight FROM flight WHERE flight_id = p_flight_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Flight % does not exist', p_flight_id;
  END IF;
  IF v_flight.status <> 'SCHEDULED' OR v_flight.departure_time <= now() THEN
    RAISE EXCEPTION 'Flight % is not open for booking', v_flight.flight_number;
  END IF;

  SELECT * INTO v_seat
  FROM seat
  WHERE aircraft_id = v_flight.aircraft_id
    AND seat_number = UPPER(p_seat_number);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Seat % does not exist on flight %',
                    UPPER(p_seat_number), v_flight.flight_number;
  END IF;

  IF v_uid IS NOT NULL THEN
    v_email := LOWER(auth.jwt() ->> 'email');

    SELECT passenger_id INTO v_passenger FROM passenger WHERE user_id = v_uid;

    IF v_passenger IS NULL THEN
      SELECT passenger_id INTO v_passenger
      FROM passenger WHERE email = v_email AND user_id IS NULL;
      IF v_passenger IS NOT NULL THEN
        UPDATE passenger SET user_id = v_uid WHERE passenger_id = v_passenger;
      END IF;
    END IF;
  ELSE
    v_email := LOWER(p_email);
    SELECT passenger_id INTO v_passenger FROM passenger WHERE email = v_email;
  END IF;

  IF v_passenger IS NULL THEN
    INSERT INTO passenger (first_name, last_name, email, phone, user_id)
    VALUES (p_first_name, p_last_name, v_email, p_phone, v_uid)
    RETURNING passenger_id INTO v_passenger;
  END IF;

  v_price := CASE WHEN v_seat.seat_class = 'BUSINESS'
                  THEN v_flight.base_fare * 2.5
                  ELSE v_flight.base_fare END;

  LOOP
    v_pnr := '';
    FOR i IN 1..6 LOOP
      v_pnr := v_pnr || SUBSTR(v_chars, FLOOR(RANDOM() * 32)::INT + 1, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM booking WHERE pnr = v_pnr);
  END LOOP;

  INSERT INTO booking (pnr, passenger_id, flight_id, seat_id, price)
  VALUES (v_pnr, v_passenger, p_flight_id, v_seat.seat_id, v_price);

  RETURN v_pnr;

EXCEPTION
  WHEN unique_violation THEN
    GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
    IF v_constraint = 'one_booking_per_seat' THEN
      RAISE EXCEPTION 'Seat % is already booked on flight %',
                      UPPER(p_seat_number), v_flight.flight_number;
    ELSIF v_constraint = 'one_seat_per_passenger' THEN
      RAISE EXCEPTION 'You already have a seat on flight %', v_flight.flight_number;
    ELSIF v_constraint = 'passenger_email_key' THEN
      RAISE EXCEPTION 'This email belongs to a different account';
    ELSE
      RAISE;
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION book_seat(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) FROM anon;

CREATE OR REPLACE FUNCTION my_bookings()
RETURNS TABLE (
  pnr             TEXT,
  flight_number   VARCHAR,
  from_city       VARCHAR,
  from_code       TEXT,
  to_city         VARCHAR,
  to_code         TEXT,
  departure_time  TIMESTAMP,
  arrival_time    TIMESTAMP,
  seat_number     VARCHAR,
  seat_class      VARCHAR,
  price           NUMERIC,
  status          VARCHAR,
  booked_at       TIMESTAMP,
  cancelled_at    TIMESTAMP
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.pnr::TEXT,
         f.flight_number,
         o.city, o.iata_code::TEXT,
         d.city, d.iata_code::TEXT,
         f.departure_time,
         f.arrival_time,
         s.seat_number,
         s.seat_class,
         b.price,
         b.status,
         b.booked_at,
         b.cancelled_at
  FROM booking b
  JOIN passenger p ON p.passenger_id = b.passenger_id
  JOIN flight f    ON f.flight_id    = b.flight_id
  JOIN airport o   ON o.airport_id   = f.origin_id
  JOIN airport d   ON d.airport_id   = f.destination_id
  JOIN seat s      ON s.seat_id      = b.seat_id
  WHERE p.user_id = auth.uid()
  ORDER BY f.departure_time DESC;
$$;

REVOKE EXECUTE ON FUNCTION my_bookings() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION my_bookings() TO authenticated;

SELECT passenger_id, email, user_id FROM passenger ORDER BY passenger_id;
