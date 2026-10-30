CREATE OR REPLACE FUNCTION get_booking(p_pnr VARCHAR, p_email VARCHAR)
RETURNS TABLE (
  pnr             TEXT,
  passenger_name  TEXT,
  flight_number   VARCHAR,
  from_city       VARCHAR,
  to_city         VARCHAR,
  departure_time  TIMESTAMP,
  seat_number     VARCHAR,
  seat_class      VARCHAR,
  price           NUMERIC,
  status          VARCHAR,
  cancelled_at    TIMESTAMP
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.pnr::TEXT,
         p.first_name || ' ' || p.last_name,
         f.flight_number,
         o.city,
         d.city,
         f.departure_time,
         s.seat_number,
         s.seat_class,
         b.price,
         b.status,
         b.cancelled_at
  FROM booking b
  JOIN passenger p ON p.passenger_id = b.passenger_id
  JOIN flight f    ON f.flight_id    = b.flight_id
  JOIN airport o   ON o.airport_id   = f.origin_id
  JOIN airport d   ON d.airport_id   = f.destination_id
  JOIN seat s      ON s.seat_id      = b.seat_id
  WHERE b.pnr   = UPPER(TRIM(p_pnr))
    AND p.email = LOWER(TRIM(p_email));
$$;

CREATE OR REPLACE FUNCTION cancel_booking(p_pnr VARCHAR, p_email VARCHAR)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking_id  INTEGER;
  v_status      VARCHAR;
  v_departure   TIMESTAMP;
  v_seat        VARCHAR;
  v_flight_no   VARCHAR;
BEGIN
  SELECT b.booking_id, b.status, f.departure_time, s.seat_number, f.flight_number
  INTO   v_booking_id, v_status, v_departure, v_seat, v_flight_no
  FROM booking b
  JOIN passenger p ON p.passenger_id = b.passenger_id
  JOIN flight f    ON f.flight_id    = b.flight_id
  JOIN seat s      ON s.seat_id      = b.seat_id
  WHERE b.pnr   = UPPER(TRIM(p_pnr))
    AND p.email = LOWER(TRIM(p_email))
  FOR UPDATE OF b;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No booking found with that PNR and email';
  END IF;

  IF v_status = 'CANCELLED' THEN
    RAISE EXCEPTION 'This booking is already cancelled';
  END IF;

  IF v_departure <= now() THEN
    RAISE EXCEPTION 'This flight has already departed, so it can no longer be cancelled';
  END IF;

  UPDATE booking
  SET status = 'CANCELLED', cancelled_at = now()
  WHERE booking_id = v_booking_id;

  RETURN 'Booking ' || UPPER(TRIM(p_pnr)) || ' cancelled. Seat ' || v_seat ||
         ' on ' || v_flight_no || ' is available again.';
END;
$$;

REVOKE EXECUTE ON FUNCTION get_booking(VARCHAR, VARCHAR)    FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION cancel_booking(VARCHAR, VARCHAR) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION get_booking(VARCHAR, VARCHAR)    TO anon;
GRANT  EXECUTE ON FUNCTION cancel_booking(VARCHAR, VARCHAR) TO anon;
