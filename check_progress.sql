SELECT table_name,
       CASE table_type WHEN 'BASE TABLE' THEN 'table' ELSE 'view' END AS kind
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY kind, table_name;

SELECT 'airport'        AS table_name, COUNT(*) AS rows FROM airport
UNION ALL SELECT 'aircraft_model', COUNT(*) FROM aircraft_model
UNION ALL SELECT 'aircraft',       COUNT(*) FROM aircraft
UNION ALL SELECT 'seat',           COUNT(*) FROM seat
UNION ALL SELECT 'passenger',      COUNT(*) FROM passenger
UNION ALL SELECT 'flight',         COUNT(*) FROM flight
UNION ALL SELECT 'booking',        COUNT(*) FROM booking;

SELECT DISTINCT event_object_table AS on_table, trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY on_table;

SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;
