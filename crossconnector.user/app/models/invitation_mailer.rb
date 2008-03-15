class InvitationMailer < ActionMailer::Base

  def invite(invitation, sent_at = Time.now)
    @subject    = 'CrossConnector Beta Invitation'
    @recipients = invitation.invitation_code
    @from       = App::CONFIG[:administrator_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["invitation"] = invitation
  end
  
end
