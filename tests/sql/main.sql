-- Advanced SQL smoke test
WITH active_users AS (
  SELECT u.id, u.email, u.created_at
  FROM users u
  WHERE u.status = 'active'
),
recent_orders AS (
  SELECT o.user_id, COUNT(*) AS order_count, SUM(o.total_cents) AS total_cents
  FROM orders o
  WHERE o.created_at >= NOW() - INTERVAL '30 days'
  GROUP BY o.user_id
)
SELECT
  au.id,
  au.email,
  COALESCE(ro.order_count, 0) AS order_count,
  COALESCE(ro.total_cents, 0) AS total_cents,
  CASE
    WHEN COALESCE(ro.total_cents, 0) > 100000 THEN 'vip'
    WHEN COALESCE(ro.total_cents, 0) > 0 THEN 'buyer'
    ELSE 'active-no-orders'
  END AS segment
FROM active_users au
LEFT JOIN recent_orders ro ON ro.user_id = au.id
ORDER BY total_cents DESC, au.created_at DESC
LIMIT 100;

-- diagnostics test idea:
-- SELECT * FROM non_existing_table;
