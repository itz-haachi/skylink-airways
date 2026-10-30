CREATE TABLE flight (
  flight_id       INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  flight_number   VARCHAR(8)    NOT NULL,
  aircraft_id     INTEGER       NOT NULL REFERENCES aircraft(aircraft_id),
  origin_id       INTEGER       NOT NULL REFERENCES airport(airport_id),
  destination_id  INTEGER       NOT NULL REFERENCES airport(airport_id),
  departure_time  TIMESTAMP     NOT NULL,
  arrival_time    TIMESTAMP     NOT NULL,
  base_fare       NUMERIC(8,2)  NOT NULL,
  status          VARCHAR(10)   NOT NULL DEFAULT 'SCHEDULED',
  UNIQUE (flight_number, departure_time)
);

CREATE OR REPLACE FUNCTION check_flight_valid()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.origin_id = NEW.destination_id THEN
    RAISE EXCEPTION 'Origin and destination cannot be the same airport';
  END IF;

  IF NEW.arrival_time <= NEW.departure_time THEN
    RAISE EXCEPTION 'Arrival time must be after departure time';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_flight
BEFORE INSERT OR UPDATE ON flight
FOR EACH ROW
EXECUTE FUNCTION check_flight_valid();

INSERT INTO flight (flight_number, aircraft_id, origin_id, destination_id,
                    departure_time, arrival_time, base_fare) VALUES
  ('SK101', 1,  1, 3, CURRENT_DATE + 1 + TIME '06:00', CURRENT_DATE + 1 + TIME '07:45', 5200),
  ('SK102', 1,  3, 1, CURRENT_DATE + 1 + TIME '09:00', CURRENT_DATE + 1 + TIME '10:45', 5200),
  ('SK201', 10, 3, 5, CURRENT_DATE + 1 + TIME '07:00', CURRENT_DATE + 1 + TIME '09:40', 6800),
  ('SK202', 10, 5, 3, CURRENT_DATE + 1 + TIME '11:00', CURRENT_DATE + 1 + TIME '13:40', 6800),
  ('SK301', 21, 5, 4, CURRENT_DATE + 1 + TIME '08:00', CURRENT_DATE + 1 + TIME '09:00', 3900),
  ('SK302', 21, 4, 5, CURRENT_DATE + 1 + TIME '10:00', CURRENT_DATE + 1 + TIME '11:00', 3900),
  ('SK401', 6,  2, 3, CURRENT_DATE + 1 + TIME '06:30', CURRENT_DATE + 1 + TIME '08:45', 6100),
  ('SK402', 6,  3, 2, CURRENT_DATE + 1 + TIME '10:00', CURRENT_DATE + 1 + TIME '12:15', 6100),
  ('SK501', 15, 4, 5, CURRENT_DATE + 1 + TIME '13:00', CURRENT_DATE + 1 + TIME '14:10', 3500),
  ('SK502', 15, 5, 4, CURRENT_DATE + 1 + TIME '15:30', CURRENT_DATE + 1 + TIME '16:40', 3500),
  ('SK601', 3,  1, 5, CURRENT_DATE + 2 + TIME '07:00', CURRENT_DATE + 2 + TIME '09:30', 7400),
  ('SK602', 3,  5, 1, CURRENT_DATE + 2 + TIME '11:00', CURRENT_DATE + 2 + TIME '13:30', 7400);
