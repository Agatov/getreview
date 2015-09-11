class SessionsController < ApplicationController
  def new
  end

  def create
    auth = request.env["omniauth.auth"]

    reviewer = Reviewer.find_by_provider_and_uid auth.provider, auth.uid

    unless reviewer
      reviewer = Reviewer.new
      reviewer.name = auth.info.first_name + " " + auth.info.last_name
      reviewer.provider = auth.provider
      reviewer.uid = auth.uid

      case auth.provider
        when "vkontakte"
          reviewer.url = auth.info.urls.Vkontakte
          reviewer.remote_avatar_url = auth.extra.raw_info.photo_200_orig!

        when "odnoklassniki"
          reviewer.url = auth.info.urls.Odnoklassniki
          reviewer.remote_avatar_url auth.info.image

      end

      reviewer.save
    end

    session[:reviewer_id] = reviewer.id
    
    redirect_to "/board/#{session[:widget]}"
  end
end