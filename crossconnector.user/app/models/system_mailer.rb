
class SystemMailer < ActionMailer::Base
  helper ApplicationHelper

  def message(message, sent_at = Time.now)
    @subject    = "CrossConnector - #{message.subject}"
    @from       = message.created_by.email
    @sent_on    = sent_at
    @headers    = {}
    #This works, but it would be nice if it was more compact: 
    # Break this out into a function...
    @recipients = message.addresses.collect {|address| address.email}
    for group in message.groups
      for address in group.addresses
        @recipients.push(address.email) unless @recipients.include?(address.email)
      end
    end
    @body["message"] = message
  end

  def project(project,sent_at = Time.now)
    @subject    = "CrossConnector - #{project.name}"
    @from       = project.created_by.email
    @sent_on    = sent_at
    @headers    = {}
    #This works, but it would be nice if it was more compact: 
    # Break this out into a function...
    @recipients = project.addresses.collect {|address| address.email}
    for group in project.groups
      for address in group.addresses
        @recipients.push(address.email) unless @recipients.include?(address.email)
      end
    end
    @body["project"] = project
  end

  def file(sent_at = Time.now)
    @subject    = 'SystemMailer#file'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
  
  
  def leader_welcome(leader,sent_at = Time.now)
    @subject    = "Welcome to CrossConnector"
    @recipients = leader.email
    @from       = leader.homebase.created_by.email
    @sent_on    = sent_at
    @headers    = {}
    @body["leader"] = leader
  end
  
  def forgot_password(user,sent_at = Time.now)
    @subject    = "Your CrossConnector Password"
    @recipients = user.email
    @from       = "support@crossconnector.com"
    @sent_on    = sent_at
    @headers    = {}
    @body["user"] = user
  end
  
  def cancellation_confirmation(homebase,sent_at = Time.now)
    @subject    = "Your CrossConnector Account has been Canceled"
    @recipients = homebase.created_by.email
    @from       = "support@crossconnector.com"
    @sent_on    = sent_at
    @headers    = {}
    @body["homebase"] = homebase
  end
  
  def cancellation_notification(homebase,sent_at = Time.now)
    @subject    = "Cancellation Notification: #{homebase.name}"
    @recipients = "support@crossconnector.com"
    @from       = "support@crossconnector.com"
    @sent_on    = sent_at
    @headers    = {}
    @body["homebase"] = homebase
  end
end
