SELECT setseed(0.42);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT
  f,
  l,
  d,
  round((CASE d
           WHEN 'IT'        THEN 45000
           WHEN 'Finance'   THEN 40000
           WHEN 'Sales'     THEN 35000
           WHEN 'Marketing' THEN 34000
           WHEN 'HR'        THEN 33000
           ELSE                  32000
         END + random() * 18000)::numeric, -2),
  DATE '2015-01-01' + floor(random() * 3287)::int
FROM (
  SELECT f, l,
         (ARRAY['Operations','Finance','Sales','HR','IT','Marketing'])
           [1 + floor(random() * 6)::int] AS d
  FROM (
    SELECT fn.f, ln.l
    FROM unnest(ARRAY[
      'Somchai','Somsak','Suda','Malee','Nattapong','Kanya','Anan','Pimchanok',
      'Teerapat','Orn','Wichai','Jirapa','Ratchanon','Siriporn','Thanakrit',
      'Narong','Chanida','Preecha','Waraporn','Kittipong','Arisa','Boonchu',
      'Chatchai','Darunee','Ekkachai','Fah','Gamon','Hathairat','Issara',
      'Jakkrit','Kamon','Lalita','Manit','Napat','Oraphan','Pattarapong',
      'Rungnapha','Sasithorn','Tawan','Umaporn'
    ]) AS fn(f)
    CROSS JOIN unnest(ARRAY[
      'Wongsa','Srisuk','Chaiyasit','Boonmee','Prasert','Kaewjai','Thongdee',
      'Rattanakul','Sukjai','Phromma','Saelim','Maneerat','Chaisri','Netrakhun',
      'Sombat','Jaidee','Thongchai','Kaewta','Phetcharat','Suksan','Chaiyaporn',
      'Bunma','Srisai','Chaiyong','Wongphet','Kaewkham','Sukhum','Rattana',
      'Dechapan','Intara','Phromsri','Chaiwat','Charoen','Kongkaew','Limsakul',
      'Mongkol','Nakorn','Oudom','Pongsak','Rojana'
    ]) AS ln(l)
    WHERE NOT EXISTS (
      SELECT 1 FROM employees e
      WHERE e.first_name = fn.f AND e.last_name = ln.l
    )
    ORDER BY random()
    LIMIT 230
  ) names
) x;