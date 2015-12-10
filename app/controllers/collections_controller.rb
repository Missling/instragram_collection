require 'httparty'
require 'instagram'

class CollectionsController < ApplicationController

  def index
    @collections = Collection.all
  end

  def new
    @collection = Collection.new
  end

  def show
    @collection = Collection.find(params[:id])
    @photos = @collection.photos
  end

  def create
    if params[:collection]["end_date"].present? && params[:collection]["end_date"].to_date.past?
      end_date = params[:collection]["end_date"].to_date
    else
      end_date = Time.now.to_date
    end

    @collection = Collection.new(
      hashtag: params[:collection]["hashtag"],
      start_date: params[:collection]["start_date"].to_datetime,
      end_date: end_date,
      )

    @collection.save
       
    fetch_photo(@collection.hashtag, @collection.start_date, @collection.end_date)

    if @collection.save
      redirect_to root_path
    else
      render 'new'
    end
  end

  def fetch_photo(hashtag, start_date, end_date)
    response = HTTParty.get("https://api.instagram.com/v1/tags/#{hashtag}/media/recent?access_token=#{ENV[‘API_KEY’]}")

    response["data"].each do |photo|
      created_time = Time.at(photo["created_time"].to_i).to_date

      next unless (start_date..end_date).cover?(created_time)

      @photo = Photo.new(
        tag_time: created_time,
        link: photo["link"],
        user: photo["user"]["username"],
        photo_id: photo["id"],
        collection_id: @collection.id,
      )

      if !photo["caption"]["text"].downcase.include?(hashtag.downcase)

        comment_response = HTTParty.get("https://api.instagram.com/v1/media/#{photo["id"]}/comments?access_token=#{ENV[‘API_KEY’]}")

        comment_response["data"].each do |comment|

          if comment["text"].downcase.include?(hashtag.downcase)

            @photo.tag_time = comment["created_time"]
            break
          end
        end
      end

      @photo.save 
    end
  end
end
