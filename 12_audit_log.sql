CREATE TABLE booking_audit (
  audit_id      INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  booking_id    INTEGER      NOT NULL,
  pnr           CHAR(6)      NOT NULL,
  action        VARCHAR(10)  NOT NULL,
  flight_id     INTEGER      NOT NULL,
  seat_id       INTEGER      NOT NULL,
  passenger_id  INTEGER      NOT NULL,
  changed_at    TIMESTAMP    NOT NULL DEFAULT now(),
  changed_by    TEXT         NOT NULL DEFAULT current_user
);

ALTER TABLE booking_audit ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION log_booking_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO booking_audit (booking_id, pnr, action, flight_id, seat_id, passenger_id)
    VALUES (NEW.booking_id, NEW.pnr, NEW.status, NEW.flight_id, NEW.seat_id, NEW.passenger_id);

  ELSIF TG_OP = 'UPDATE' AND OLD.status <> NEW.status THEN
    INSERT INTO booking_audit (booking_id, pnr, action, flight_id, seat_id, passenger_id)
    VALUES (NEW.booking_id, NEW.pnr, NEW.status, NEW.flight_id, NEW.seat_id, NEW.passenger_id);
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_booking_audit
AFTER INSERT OR UPDATE OF status ON booking
FOR EACH ROW
EXECUTE FUNCTION log_booking_change();

INSERT INTO booking_audit (booking_id, pnr, action, flight_id, seat_id, passenger_id, changed_at, changed_by)
SELECT booking_id, pnr, 'CONFIRMED', flight_id, seat_id, passenger_id, booked_at, 'backfill'
FROM booking;

INSERT INTO booking_audit (booking_id, pnr, action, flight_id, seat_id, passenger_id, changed_at, changed_by)
SELECT booking_id, pnr, 'CANCELLED', flight_id, seat_id, passenger_id, cancelled_at, 'backfill'
FROM booking
WHERE status = 'CANCELLED';

SELECT a.changed_at, a.action, a.pnr, f.flight_number, s.seat_number,
       p.first_name || ' ' || p.last_name AS passenger
FROM booking_audit a
JOIN flight f    ON f.flight_id    = a.flight_id
JOIN seat s      ON s.seat_id      = a.seat_id
JOIN passenger p ON p.passenger_id = a.passenger_id
ORDER BY a.changed_at DESC
LIMIT 20;
