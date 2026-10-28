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

SELECT affix_id, role, COUNT(*) AS ranks,
       MIN(spell_id) AS first_spell,
       MAX(spell_id) AS last_spell
FROM manastorm_affix_rank_spell
GROUP BY affix_id, role
ORDER BY affix_id, role;

SELECT u.unlock_id,u.unlock_kind,u.trigger_depth,u.mode_mask,u.track_mask,
       u.completion_message_id,u.enabled,
       g.grant_type,g.content_id,g.enabled AS grant_enabled
FROM manastorm_unlock u
JOIN manastorm_unlock_grant g ON g.unlock_id=u.unlock_id
WHERE u.unlock_id IN
(900011,900013,900016,900019,900021,900023,900026,
 900028,900031,900033,900039,900041,900061,900101)
ORDER BY u.trigger_depth,u.unlock_id;
