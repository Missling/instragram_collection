class Photo < ActiveRecord::Base
  belongs_to :collection
  validates :photo_id, uniqueness: true
end
