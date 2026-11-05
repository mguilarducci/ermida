require "test_helper"

class MagicLinkDeliveryTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sign-in instructions go out by email later" do
    link = create(:magic_link)

    assert_enqueued_email_with MagicLinkMailer, :sign_in_instructions, args: [link] do
      MagicLinkDelivery.sign_in_instructions(link).deliver_later
    end
  end
end
