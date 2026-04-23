class CreateSpaceMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :space_memberships do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.timestamps
    end

    add_index :space_memberships, [:user_id, :space_id], unique: true
  end
end
