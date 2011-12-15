require 'twitter'

class SiriProxy::Plugin::Twitter < SiriProxy::Plugin
  def initialize(config = {})
    @config = config 
    
    ::Twitter.configure do |config|
      config.consumer_key = @config['consumer_key'] 
      config.consumer_secret = @config['consumer_secret']
      config.oauth_token = @config['oauth_token'] 
      config.oauth_token_secret = @config['oauth_token_secret']
    end 

    @twitterClient = ::Twitter::Client.new
  end

  listen_for /twitter update (.+)/i do |tweetText|
    say "Here is your tweet:"

    # send a "Preview" of the Tweet
    object = SiriAddViews.new
    object.make_root(last_ref_id)
    answer = SiriAnswer.new("Tweet", [
      SiriAnswerLine.new('logo','http://cl.ly/1l040J1A392n0M1n1g35/content'), # this just makes things looks nice, but is obviously specific to my username
      SiriAnswerLine.new(tweetText)
    ])
    object.views << SiriAnswerSnippet.new([answer])
    send_object object

    if confirm "Ready to send it?"
      say "Posting to twitter..."
      Thread.new {
        begin
          @twitterClient.update(tweetText)
          say "Ok it has been posted."
        rescue Exception
          pp $!
          say "Sorry, I encountered an error: #{$!}"
        ensure
          request_completed
        end
      }
    else
      say "Ok I won't send it."
      request_completed
    end
  end
end
