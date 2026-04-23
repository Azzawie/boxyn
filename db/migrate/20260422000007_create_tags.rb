class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.references :space, null: false, foreign_key: true
      t.timestamps
    end

    add_index :tags, [:name, :space_id], unique: true
  end
end
