ALTER POLICY "public read" ON airport        TO anon, authenticated;
ALTER POLICY "public read" ON aircraft_model TO anon, authenticated;
ALTER POLICY "public read" ON aircraft       TO anon, authenticated;
ALTER POLICY "public read" ON seat           TO anon, authenticated;
ALTER POLICY "public read" ON flight         TO anon, authenticated;
ALTER POLICY "public read" ON booking        TO anon, authenticated;

REVOKE SELECT ON booking FROM authenticated;
GRANT  SELECT (flight_id, seat_id, status) ON booking TO authenticated;

GRANT EXECUTE ON FUNCTION book_seat(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_booking(VARCHAR, VARCHAR)    TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_booking(VARCHAR, VARCHAR) TO authenticated;

SELECT tablename, roles
FROM pg_policies
WHERE policyname = 'public read'
ORDER BY tablename;
