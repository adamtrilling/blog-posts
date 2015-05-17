class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :text
      t.boolean :completed

      t.timestamps null: false
    end
  end
end
