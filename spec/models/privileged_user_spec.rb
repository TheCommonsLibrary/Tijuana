require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PrivilegedUser do

  describe 'privileged user password' do
    before :each do
      @admin = create(:admin_user)
    end

    context 'password complexity requirements' do
      it 'should validate that password meets format requirements' do
        @admin.update_attributes(:password => 'some_password',
                                 :password_confirmation => 'some_password')
        @admin.should_not be_valid

        @admin.update_attributes(:password => 'pAsSw0rD1',
                                 :password_confirmation => 'pAsSw0rD1')
        @admin.should be_valid
      end

      it 'should validate that password has at least 6 characters' do
        @admin.update_attributes(:password => 'pAs1',
                                 :password_confirmation => 'pAs1')
        @admin.should_not be_valid
      end

      it 'should validate that new password is not a previously used password' do
        @admin.update_attributes(:password => 'pAsSw0rD1',
                                 :password_confirmation => 'pAsSw0rD1')
        @admin.should be_valid

        @admin.update_attributes(:password => 'pAsSw0rD1',
                                 :password_confirmation => 'pAsSw0rD1')
        @admin.should_not be_valid
      end
    end

    context 'two factor authentication' do
      before do
        PasswordMailer.deliveries.clear
      end

      it 'should receive an email with secure code when login' do
        @admin.send_two_factor_authentication_code
        PasswordMailer.should have(1).deliveries
        mail = PasswordMailer.deliveries.last
        mail.should have_body_text(/#{@admin.otp_code}/)
        mail.should have_subject(/Two factor authentication instructions/)
        mail.should deliver_to(@admin.email)
      end
    end
  end
end
