module InvitationLinks
  extend ActiveSupport::Concern

  private

  def store_invitation_link(invitation)
    flash[:invitation_url] = invitation_url(invitation.raw_token)
  end
end
