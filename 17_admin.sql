CREATE TABLE admin_user (
  user_id   UUID       PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  added_at  TIMESTAMP  NOT NULL DEFAULT now()
);

ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON admin_user FROM anon, authenticated;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM admin_user WHERE user_id = auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION is_admin() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION is_admin() TO authenticated;

CREATE OR REPLACE FUNCTION admin_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admins only' USING ERRCODE = '42501';
  END IF;

  RETURN jsonb_build_object(

    'summary', (
      SELECT jsonb_build_object(
        'tickets',   COUNT(*) FILTER (WHERE status = 'CONFIRMED'),
        'revenue',   COALESCE(SUM(price) FILTER (WHERE status = 'CONFIRMED'), 0),
        'cancelled', COUNT(*) FILTER (WHERE status = 'CANCELLED'),
        'bookings',  COUNT(*),
        'avg_load',  (SELECT ROUND(AVG(load_factor_pct), 1) FROM flight_availability))
      FROM booking),

    'routes', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.revenue DESC), '[]')
      FROM (SELECT o.iata_code || ' → ' || d.iata_code AS route,
                   COUNT(b.booking_id) AS tickets_sold,
                   SUM(b.price)        AS revenue
            FROM booking b
            JOIN flight f  ON f.flight_id  = b.flight_id
            JOIN airport o ON o.airport_id = f.origin_id
            JOIN airport d ON d.airport_id = f.destination_id
            WHERE b.status = 'CONFIRMED'
            GROUP BY o.iata_code, d.iata_code) r),

    'load', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.load_factor_pct DESC, r.departure_time), '[]')
      FROM (SELECT flight_number, from_code, to_code, departure_time,
                   seats_booked, total_seats, load_factor_pct
            FROM flight_availability) r),

    'cities', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.revenue DESC), '[]')
      FROM (SELECT a.city, a.iata_code,
                   COUNT(b.booking_id)       AS tickets_sold,
                   COALESCE(SUM(b.price), 0) AS revenue
            FROM airport a
            LEFT JOIN flight f  ON f.origin_id = a.airport_id
            LEFT JOIN booking b ON b.flight_id = f.flight_id AND b.status = 'CONFIRMED'
            GROUP BY a.airport_id, a.city, a.iata_code) r),

    'classes', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.revenue DESC), '[]')
      FROM (SELECT s.seat_class,
                   COUNT(*)     AS tickets,
                   SUM(b.price) AS revenue,
                   ROUND(100.0 * SUM(b.price) / SUM(SUM(b.price)) OVER (), 1) AS pct_of_revenue
            FROM booking b
            JOIN seat s ON s.seat_id = b.seat_id
            WHERE b.status = 'CONFIRMED'
            GROUP BY s.seat_class) r),

    'cancellations', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.cancel_rate_pct DESC), '[]')
      FROM (SELECT f.flight_number,
                   COUNT(*)                                       AS total_bookings,
                   COUNT(*) FILTER (WHERE b.status = 'CANCELLED') AS cancelled,
                   ROUND(100.0 * COUNT(*) FILTER (WHERE b.status = 'CANCELLED')
                         / NULLIF(COUNT(*), 0), 1)                AS cancel_rate_pct
            FROM booking b
            JOIN flight f ON f.flight_id = b.flight_id
            GROUP BY f.flight_number
            HAVING COUNT(*) FILTER (WHERE b.status = 'CANCELLED') > 0) r),

    'repeat', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.bookings DESC, r.total_spent DESC), '[]')
      FROM (SELECT p.first_name || ' ' || p.last_name AS passenger,
                   COUNT(*)     AS bookings,
                   SUM(b.price) AS total_spent
            FROM passenger p
            JOIN booking b ON b.passenger_id = p.passenger_id
            WHERE b.status = 'CONFIRMED'
            GROUP BY p.passenger_id, p.first_name, p.last_name
            HAVING COUNT(*) > 1
            ORDER BY bookings DESC, total_spent DESC
            LIMIT 10) r),

    'idle', (
      SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.based_at, r.registration), '[]')
      FROM (SELECT ac.registration, m.model_name, ap.city AS based_at
            FROM aircraft ac
            JOIN aircraft_model m ON m.model_id   = ac.model_id
            JOIN airport ap       ON ap.airport_id = ac.base_airport_id
            WHERE NOT EXISTS (SELECT 1 FROM flight f WHERE f.aircraft_id = ac.aircraft_id)) r)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION admin_dashboard() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION admin_dashboard() TO authenticated;

SELECT u.email, a.added_at FROM admin_user a JOIN auth.users u ON u.id = a.user_id;
