class UsersController < ApplicationController
  def index
  end

  ##
  # Get temporary credentials and redirect the user 
  # to Evernote for authoriation
  ##
  def authorize
    callback_url = request.url.chomp("authorize").concat("callback")
    begin
      consumer = OAuth::Consumer.new(
        OAUTH_CONSUMER_KEY, 
        OAUTH_CONSUMER_SECRET,
        {
          :site => EVERNOTE_SERVER,
          :request_token_path => "/oauth",
          :access_token_path => "/oauth",
          :authorize_path => "/OAuth.action"
      })

      session[:request_token] = consumer.get_request_token(:oauth_callback => callback_url)
      redirect_to session[:request_token].authorize_url
    rescue Exception => e
      @last_error = "Error obtaining temporary credentials: #{e.message}"
      render 'application/error'
    end
  end
  
  ##
  # Receive callback from the Evernote authorization page and exchange the
  # temporary credentials for an token credentials.
  ##
  def callback
    if (params['oauth_verifier'].nil?)
      @last_error = "Content owner did not authorize the temporary credentials"
      render 'application/error'
    else
      oauth_verifier = params['oauth_verifier']
      begin
        access_token = session[:request_token].get_access_token(:oauth_verifier => oauth_verifier)
        session[:access_token] = access_token
        redirect_to '/users/list_images'
      rescue Exception => e
        @last_error = e.message
        render 'application/error'
      end
    end
  end

  def list_images
    items_per_page = 12
    min_size = 30
    max_size = 800
    if !params[:page].blank?
      @current_page = params[:page].to_i
      offset = (items_per_page * (params[:page].to_i - 1))
      @image_resources = get_images(offset, items_per_page, min_size, max_size)
    else
      @current_page = 1
      @image_resources = get_images(0, items_per_page, min_size, max_size)
    end
    @has_more = true unless @image_resources.size < items_per_page || @image_resources.blank?
  end    

  def get_images offset, items_per_page, min_size, max_size
    image_filter = Evernote::EDAM::NoteStore::NoteFilter.new 
    image_filter.words = "resource:image/*"
    image_note_list = note_store.findNotes(auth_token, image_filter, offset, items_per_page)
    image_resources = Array.new
    image_note_list.notes.each do |note|
      note.resources.each do |resource|
        image_resources << resource unless !right_size?(resource, min_size, max_size)
      end
    end
    image_resources
  end
end
