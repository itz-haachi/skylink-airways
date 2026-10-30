CREATE TABLE passenger (
  passenger_id   INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name     VARCHAR(50)   NOT NULL,
  last_name      VARCHAR(50)   NOT NULL,
  email          VARCHAR(100)  NOT NULL UNIQUE,
  phone          VARCHAR(15),
  date_of_birth  DATE
);

INSERT INTO passenger (first_name, last_name, email, phone, date_of_birth) VALUES
  ('Aarav',   'Sharma',   'aarav.sharma@example.com',   '9876543210', '1998-04-12'),
  ('Priya',   'Iyer',     'priya.iyer@example.com',     '9876543211', '2001-09-23'),
  ('Rahul',   'Das',      'rahul.das@example.com',      '9876543212', '1995-01-30'),
  ('Ananya',  'Reddy',    'ananya.reddy@example.com',   '9876543213', '2003-06-05'),
  ('Vikram',  'Singh',    'vikram.singh@example.com',   '9876543214', '1989-11-17'),
  ('Divya',   'Nair',     'divya.nair@example.com',     '9876543215', '1999-02-08'),
  ('Karthik', 'Menon',    'karthik.menon@example.com',  '9876543216', '1993-08-14'),
  ('Sneha',   'Debbarma', 'sneha.debbarma@example.com', '9876543217', '2000-12-01'),
  ('Arjun',   'Gill',     'arjun.gill@example.com',     '9876543218', '1997-07-22'),
  ('Meera',   'Bose',     'meera.bose@example.com',     '9876543219', '2002-03-15');
