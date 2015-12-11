require 'httparty'
require 'instagram'
require 'puma'

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
       
    fetch_photos(@collection)

    if @collection.save
      redirect_to root_path
    else
      render 'new'
    end
  end

  def fetch_photos(collection)
    response = HTTParty.get("https://api.instagram.com/v1/tags/#{collection.hashtag}/media/recent?access_token=#{ENV['API_KEY']}")

    save_photos(response, collection)
  end


  def save_photos(response, collection)
    while response
      response["data"].each do |photo|
        created_time = Time.at(photo["created_time"].to_i).to_date 

        next if created_time > collection.end_date
        break if created_time < collection.start_date

        @photo = Photo.new(
          tag_time: created_time,
          link: photo["link"],
          user: photo["user"]["username"],
          photo_id: photo["id"],
          collection_id: collection.id,
        )

        if !photo["caption"]["text"].downcase.include?(collection.hashtag.downcase)

          comment_response = HTTParty.get("https://api.instagram.com/v1/media/#{photo["id"]}/comments?access_token=#{ENV['API_KEY']}")

          comment_response["data"].each do |comment|

            if comment["text"].downcase.include?(collection.hashtag.downcase)

              @photo.tag_time = Time.at(comment["created_time"].to_i).to_date
              break
            end
          end
        end
        @photo.save 
      end
      next_url = response["pagination"]["next_url"]

      if next_url
        response = HTTParty.get(next_url)
      else
        response = nil
      end
    end
    collection.completed = true
    collection.save
  end

  def recover
    collection_id = params[:id]
    last_photo = Photo.where(collection_id: collection_id).last
    last_photo_id = ((last_photo.photo_id.split("_").first).to_i - 1).to_s
    last_photo_hashtag = last_photo.collection.hashtag
    collection = last_photo.collection

    response = HTTParty.get("https://api.instagram.com/v1/tags/#{last_photo_hashtag}/media/recent?access_token=#{ENV['API_KEY']}&max_tag_id=#{last_photo_id}")

    save_photos(response, collection)

    redirect_to root_path
  end
end


