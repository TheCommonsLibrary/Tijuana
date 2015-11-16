require_relative "../spec_helper"

describe PatchSingleTableInheritanceForPrivilegedUser do
  context "normal user" do
    before do
      User.create! email: "user@getup.org.au"
    end

    let(:user) { User.where(email: "user@getup.org.au").first }

    it "knows its class" do
      user.class.should eq User
    end

    it "does not need two factor authentication" do
      user.send(:need_two_factor_authentication?, nil).should eq false
    end
  end

  context "volunteer user" do
    before do
      User.create! email: "volunteer@getup.org.au", is_volunteer: true
    end

    let(:user) { User.where(email: "volunteer@getup.org.au").first }

    it "knows its class" do
      user.class.should eq PrivilegedUser
    end

    it "needs two factor authentication" do
      user.send(:need_two_factor_authentication?, nil).should eq true
    end
  end

  context "admin user" do
    before do
      User.create! email: "admin@getup.org.au", is_admin: true
    end

    let(:user) { User.where(email: "admin@getup.org.au").first }

    it "knows its class" do
      user.class.should eq PrivilegedUser
    end

    it "needs two factor authentication" do
      user.send(:need_two_factor_authentication?, nil).should eq true
    end
  end
end
