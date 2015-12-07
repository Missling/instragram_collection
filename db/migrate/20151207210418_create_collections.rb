class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :hashtag
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps null: false
    end
  end
end
