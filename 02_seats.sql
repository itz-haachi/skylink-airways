CREATE TABLE seat (
  seat_id      INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  aircraft_id  INTEGER      NOT NULL REFERENCES aircraft(aircraft_id),
  seat_number  VARCHAR(4)   NOT NULL,
  seat_row     SMALLINT     NOT NULL,
  seat_letter  CHAR(1)      NOT NULL,
  seat_class   VARCHAR(10)  NOT NULL,
  UNIQUE (aircraft_id, seat_number)
);

INSERT INTO seat (aircraft_id, seat_number, seat_row, seat_letter, seat_class)
SELECT ac.aircraft_id,
       r || SUBSTR('ABCDEF', l, 1),
       r,
       SUBSTR('ABCDEF', l, 1),
       CASE WHEN r <= 2 THEN 'BUSINESS' ELSE 'ECONOMY' END
FROM aircraft ac
JOIN aircraft_model m        ON m.model_id = ac.model_id
CROSS JOIN generate_series(1, 30) AS r
CROSS JOIN generate_series(1, 6)  AS l
WHERE r <= m.total_seats / m.seats_per_row
  AND l <= m.seats_per_row;
