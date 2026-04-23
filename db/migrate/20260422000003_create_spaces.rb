class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end
