class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :hashtag
      t.date :start_date
      t.date :end_date

      t.timestamps null: false
    end
  end
end
