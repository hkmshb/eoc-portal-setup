-- NOTES
-- execute script as thus: `psql -h localhost -U <username> -d <dbname> -f ./<relpath/to/schema.sql>`


-- set default schema to use
SET search_path=eoc_tests;



-- create sample resource tables within a transaction
DO $$
DECLARE
  TOTAL CONSTANT INTEGER := 10;
  index INTEGER := 1;
BEGIN

  -- table holding mappings of dataset to resource tables
  CREATE TABLE IF NOT EXISTS dbmap (
      id          SERIAL PRIMARY KEY
    , name        VARCHAR
    , resource_id VARCHAR UNIQUE
  );

  -- resource tables to be referenced in dbmapping
  WHILE index <= TOTAL LOOP
    EXECUTE FORMAT('
      CREATE TABLE IF NOT EXISTS %s (
          id          SERIAL PRIMARY KEY
        , name        VARCHAR
        , value       VARCHAR
      )
    ', ('resx_' || index));
    index := index + 1;
  END LOOP ;

  -- procedure to dynamically provided views with data
  -- this way a view is created to source data from procedure per
  -- dataset; view creation will succeed as procedure will always
  -- exist
  CREATE OR REPLACE VIEW redo_dataset AS
    SELECT * FROM ('SELECT * FROM resx_1');

END $$ ;


