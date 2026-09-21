-- SELECT-only helper audit for recovered Manastorm affix helpers.
SELECT req.entry AS required_entry,
       ct.entry IS NOT NULL AS exists_in_creature_template,
       COALESCE(ct.name, '<MISSING>') AS creature_name
FROM (
  SELECT 663028 entry UNION ALL SELECT 80913 UNION ALL SELECT 80914 UNION ALL
  SELECT 80917 UNION ALL SELECT 80922 UNION ALL SELECT 80923 UNION ALL
  SELECT 80924 UNION ALL SELECT 80925
) req
LEFT JOIN creature_template ct ON ct.entry=req.entry
ORDER BY req.entry;

SELECT * FROM manastorm_affix_catalog ORDER BY unlock_depth, affix_id;
