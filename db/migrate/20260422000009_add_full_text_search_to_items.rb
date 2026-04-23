class AddFullTextSearchToItems < ActiveRecord::Migration[8.1]
  def up
    add_column :items, :search_vector, :tsvector

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

    add_index :items, :search_vector, using: :gin
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS items_search_vector_trigger ON items;
      DROP FUNCTION IF EXISTS items_search_vector_update();
    SQL

    remove_column :items, :search_vector
  end
end
