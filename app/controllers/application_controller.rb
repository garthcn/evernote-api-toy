class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :image_url

  def note_store
    if @note_store.blank?
      noteStoreTransport = Thrift::HTTPClientTransport.new(access_token.params['edam_noteStoreUrl'])
      noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
      @note_store = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    end

    @note_store
  end

  def access_token
    session[:access_token]
  end

  def auth_token
    session[:access_token].token
  end

  def res_url_prefix
    session[:access_token].params[:edam_webApiUrlPrefix] + "res/"
  end

  def image_url resource
    res_url_prefix + resource.guid
  end

  def right_size? resource, min, max
    resource.width.to_i > min && resource.width.to_i < max  && resource.height.to_i > min && resource.height.to_i < max
  end
end
