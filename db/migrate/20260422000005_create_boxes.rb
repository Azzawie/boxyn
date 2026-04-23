class CreateBoxes < ActiveRecord::Migration[8.1]
  def change
    create_table :boxes do |t|
      t.references :space, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :qr_token, null: false
      t.timestamps
    end

    add_index :boxes, :qr_token, unique: true
  end
end
