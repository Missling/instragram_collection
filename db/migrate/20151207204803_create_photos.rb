class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.belongs_to :collection
      t.date :tag_time
      t.string :link
      t.string :user
      t.string :photo_id

      t.timestamps null: false
    end
  end
end
