CREATE TABLE airport (
  airport_id  INTEGER      PRIMARY KEY,
  iata_code   CHAR(3)      NOT NULL UNIQUE,
  name        VARCHAR(60)  NOT NULL,
  city        VARCHAR(40)  NOT NULL
);
CREATE TABLE aircraft_model (
  model_id       SMALLINT     PRIMARY KEY,
  manufacturer   VARCHAR(30)  NOT NULL,
  model_name     VARCHAR(30)  NOT NULL UNIQUE,
  total_seats    SMALLINT     NOT NULL,
  seats_per_row  SMALLINT     NOT NULL
);

CREATE TABLE aircraft (
  aircraft_id      INTEGER      PRIMARY KEY,
  registration     VARCHAR(10)  NOT NULL UNIQUE,
  model_id         SMALLINT     NOT NULL REFERENCES aircraft_model(model_id),
  base_airport_id  INTEGER      NOT NULL REFERENCES airport(airport_id)
);

INSERT INTO airport VALUES
  (1, 'BLR', 'Kempegowda International Airport',                  'Bengaluru'),
  (2, 'IXC', 'Shaheed Bhagat Singh International Airport',        'Chandigarh'),
  (3, 'BOM', 'Chhatrapati Shivaji Maharaj International Airport', 'Mumbai'),
  (4, 'IXA', 'Maharaja Bir Bikram Airport',                       'Agartala'),
  (5, 'CCU', 'Netaji Subhas Chandra Bose International Airport',  'Kolkata');

INSERT INTO aircraft_model VALUES
  (1, 'ATR',     'ATR 72-600', 72,  4),
  (2, 'Embraer', 'E190',       100, 4),
  (3, 'Airbus',  'A320',       180, 6);

INSERT INTO aircraft VALUES
  (1,  'VT-BLR1', 3, 1), (2,  'VT-BLR2', 3, 1), (3,  'VT-BLR3', 2, 1),
  (4,  'VT-BLR4', 2, 1), (5,  'VT-BLR5', 2, 1),
  (6,  'VT-IXC1', 2, 2), (7,  'VT-IXC2', 2, 2), (8,  'VT-IXC3', 1, 2), (9,  'VT-IXC4', 1, 2),
  (10, 'VT-BOM1', 3, 3), (11, 'VT-BOM2', 3, 3), (12, 'VT-BOM3', 3, 3),
  (13, 'VT-BOM4', 2, 3), (14, 'VT-BOM5', 2, 3),
  (15, 'VT-IXA1', 1, 4), (16, 'VT-IXA2', 1, 4), (17, 'VT-IXA3', 1, 4), (18, 'VT-IXA4', 2, 4),
  (19, 'VT-CCU1', 3, 5), (20, 'VT-CCU2', 3, 5), (21, 'VT-CCU3', 2, 5), (22, 'VT-CCU4', 2, 5);
