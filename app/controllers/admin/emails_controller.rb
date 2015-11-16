module Admin
  class EmailsController < AdminController

    # TODO: default button for press Enter, test

    crud_actions_for Email, :parent => Blast, :redirects => {
        :destroy => lambda { admin_push_path(@blast.push) },
        :create  => lambda { admin_push_path(@blast.push) },
        :update  => lambda { admin_push_path(@blast.push) }
    }

    def edit
      @user_id = User.find_by_email('info+shared_connection@getup.org.au').id #Will throw exception if user does not exist, which is what we want.
      @email_id = params[:id]
    end

    # override from CrudActions
    def save_record(model, custom_flash)
      saved = validate_and_save(button?("Validate"), model)
      proof_ok = true
      proof_ok = send_proof(custom_flash) if saved && button?("Proof")
      saved && proof_ok
    end

    def send_proof(custom_flash)
      emails = (params[:test_recipients] || "").gsub(/\s*/, "").split(",")
      if emails.blank?
        custom_flash[:error] = "Saved but Proof NOT sent as no email address(es) provided."
        return false
      else
        model.send_test!(emails)
        custom_flash[:notice] = "Saved and Proof queued for sending"
        return true
      end
    end

    def create_subject_line_test
      email = model
      subjects = params[:subject_lines].split("\n").map(&:strip).reject(&:empty?)
      email.create_subject_line_tests!(subjects)
      redirect_to admin_push_path(email.blast.push)
    end

    private

    def button?(included_text)
      params[:submit] && params[:submit].include?(included_text)
    end

    def validate_and_save(do_extended_validation, email)
      email.valid?
      if do_extended_validation
        HtmlValidator.validate_each(email, :body, email.body)
        LinksLiveValidator.validate_each(email, :body, email.body)
      end

      if email.errors.empty?
        email.save(validate: false)
      end
      email.errors.empty?
    end

  end
end
