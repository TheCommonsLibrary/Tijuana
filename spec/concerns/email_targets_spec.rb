require 'spec_helper'

describe EmailTargets do
  describe ".message_on_content_module_id" do
    let(:user){ create(:user) }
    let(:content_module){ create(:email_targets_module) }
    
    context "without a matching email" do
      it "should return null" do
        expect(user.message_on_content_module_id(content_module.id)).to be_nil
      end
    end

    context "with a matching email without a signature" do
      let!(:user_email){ create(:user_email, body: 'oh hello there', user: user, content_module: content_module) }

      it "should return the body" do
        expect(user.message_on_content_module_id(content_module.id)).to eq(user_email.body)
      end
    end

    context "with a matching email with a signature" do
      let(:message){ "Waiting times in Emergency  ....  five hrs before being attended for " +
                  "my brother-in-law who had a kidney removed and is 81yrs old!\n" + 
                  "NO complaints once attended by staff." }
      let(:body_with_signature){ "#{message}\n\n\nLiesma Lieknis\nliesmalieknis@yahoo.com.au\nNSW 2026" }
      let!(:user_email){ create(:user_email, body: body_with_signature, user: user, content_module: content_module) }

      it "should return the body stripped of the signature" do
        expect(user.message_on_content_module_id(content_module.id)).to eq(message)
      end
    end
  end
end
