class ImproveFullTextSearchTrigger < ActiveRecord::Migration[8.1]
  def up
    # Drop existing trigger and function
    execute <<-SQL
      DROP TRIGGER IF EXISTS items_search_vector_trigger ON items;
      DROP FUNCTION IF EXISTS items_search_vector_update();
    SQL

    # Create improved function with weighted tsvectors
    execute <<-SQL
      CREATE OR REPLACE FUNCTION items_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(NEW.name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B');
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER items_search_vector_trigger
      BEFORE INSERT OR UPDATE ON items
      FOR EACH ROW EXECUTE FUNCTION items_search_vector_update();
    SQL

    # Backfill existing items
    execute <<-SQL
      UPDATE items SET search_vector =
        setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B');
    SQL
  end

  def down
    # Revert to original function
    execute <<-SQL
      DROP TRIGGER IF EXISTS items_search_vector_trigger ON items;
      DROP FUNCTION IF EXISTS items_search_vector_update();
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION items_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          to_tsvector('english',
            COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.description, '')
          );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER items_search_vector_trigger
      BEFORE INSERT OR UPDATE ON items
      FOR EACH ROW EXECUTE FUNCTION items_search_vector_update();
    SQL
  end
end
