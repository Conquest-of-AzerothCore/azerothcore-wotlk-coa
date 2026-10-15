import unittest

from check_change_boundaries import violations


class BoundaryTests(unittest.TestCase):
    def test_pending_migrations_are_allowed(self):
        self.assertEqual(violations(['data/sql/updates/pending_db_world/rev.sql', 'src/server/file.cpp']), [])

    def test_all_other_sql_changes_require_an_explicit_exception(self):
        paths = ['data/sql/base/world.sql', 'data/sql/archive/rev.sql', 'data/sql/updates/db_world/rev.sql',
                 'data/sql/create/create.sql', 'modules/example/data.sql',
                 'data/sql/updates/pending_db_world_fake.sql']
        self.assertEqual(violations(paths), paths)
        self.assertEqual(violations(paths, allow_historical_sql=True), [])


if __name__ == '__main__':
    unittest.main()
