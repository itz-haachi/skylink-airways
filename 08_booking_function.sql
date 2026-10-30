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

  SELECT passenger_id INTO v_passenger FROM passenger WHERE email = LOWER(p_email);
  IF NOT FOUND THEN
    INSERT INTO passenger (first_name, last_name, email, phone)
    VALUES (p_first_name, p_last_name, LOWER(p_email), p_phone)
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
    ELSE
      RAISE;
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION book_seat(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION book_seat(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO anon;
