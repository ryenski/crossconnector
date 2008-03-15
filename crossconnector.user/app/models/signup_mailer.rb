class SignupMailer < ActionMailer::Base

  #
  #
  #   THIS FILE IS VERSION CONTROLLED
  #
  #   EDIT THIS FILE IN THE MAIN APP ONLY
  #
  #
  
  
  def welcome(user, password, sent_at = Time.now)
    @subject    = 'Welcome to CrossConnector'
    @recipients = user.email
    @from       = App::CONFIG[:support_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["user"] = user
    @body["password"] = password
  end

  def error(sent_at = Time.now)
    @subject    = 'SignupMailer#error'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
  
  def notification_of_signup(user, sent_at = Time.now)
    @subject    = "New account - #{user.homebase.name}"
    @recipients = App::CONFIG[:admin_email]
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["user"] = user
  end
  
  def notification_of_signup_failure(user, homebase, error, sent_at = Time.now)
    @subject    = 'Signup failure'
    @recipients = App::CONFIG[:admin_email]
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["user"] = user
    @body["error"] = error
    @body["homebase"] = homebase
  end
  
end
