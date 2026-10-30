BEGIN;
SELECT book_seat((SELECT flight_id FROM flight WHERE flight_number = 'SK102'),
                 '20C', 'Tab', 'One', 'tab.one@example.com') AS tab1_pnr;
SELECT pg_sleep(30);
COMMIT;

SELECT seat_status AS what_tab2_sees
FROM seat_map WHERE flight_number = 'SK102' AND seat_number = '20C';

SELECT book_seat((SELECT flight_id FROM flight WHERE flight_number = 'SK102'),
                 '20C', 'Tab', 'Two', 'tab.two@example.com') AS tab2_pnr;

BEGIN;
SELECT book_seat((SELECT flight_id FROM flight WHERE flight_number = 'SK102'),
                 '21C', 'Tab', 'Three', 'tab.three@example.com') AS tab1_pnr;
SELECT pg_sleep(30);
ROLLBACK;

SELECT book_seat((SELECT flight_id FROM flight WHERE flight_number = 'SK102'),
                 '21C', 'Tab', 'Four', 'tab.four@example.com') AS tab2_pnr;

SELECT s.seat_number, p.email, b.status
FROM booking b
JOIN passenger p ON p.passenger_id = b.passenger_id
JOIN seat s      ON s.seat_id      = b.seat_id
JOIN flight f    ON f.flight_id    = b.flight_id
WHERE f.flight_number = 'SK102' AND s.seat_number IN ('20C', '21C');

SELECT COUNT(*) AS tab_three_left FROM passenger WHERE email = 'tab.three@example.com';
