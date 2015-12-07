class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.belongs_to :collections
      t.datetime :tag_time

      t.timestamps null: false
    end
  end
end
