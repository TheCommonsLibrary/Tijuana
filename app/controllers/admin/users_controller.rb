module Admin
  class UsersController < AdminController
    PAGE_SIZE = 20
    crud_actions_for User, :redirects => {
        :create => lambda { admin_users_path },
        :update => lambda { edit_admin_user_path(@user.id) },
        :destroy => lambda { admin_users_path }
    }
    before_filter :authorize_role_changes, :only => [:create, :update]

    def index
      user_search_query = UserSearchQuery.new(params[:query], params[:query_option], params[:first_name],
                                              params[:last_name], params[:card_last_four_digits], !!params[:admins_only], params[:exact_match].present?)
      @users = user_search_query.results.includes(:postcode).paginate(:per_page => PAGE_SIZE, :page => params[:page])
    end

    def tag
      @list = List.new
    end

    def add_tags
      list = List.find(params[:list_id])
      add_tags_job = AddTagsJob.new(list, params[:tags])
      if Rails.env == "test"
        add_tags_job.perform
      else
        Delayed::Job.enqueue(add_tags_job)
      end
      redirect_to admin_users_path, :notice => "Tags are being added."
    end

    def add_external_actions
      list = List.find(params[:list_id])
      page_id = params[:external_action_page_id]

      flash_errors = validate_external_action_params(list, page_id)
      handle_external_action_response(flash_errors, page_id, list)
    end

    def create_page_add_external_actions
      list = List.find(params[:list_id])

      flash_errors = validate_new_page_external_action_params(list, params)
      page_id = flash_errors.blank? ? create_new_page(params).id : nil
      handle_external_action_response(flash_errors, page_id, list)
    end

    def transaction_report
      authorize! :export, ExcelTransactionsReport
      report = ExcelTransactionsReport.new(Transaction.filter_by(:user_id => @user.id))
      send_data(report.to_csv, :filename => "Transactions for #{@user.full_name}(#{@user.id}) (#{Date.today}).csv")
    end

    def transactions
      @transactions = @user.transactions.order('transactions.created_at DESC').page(params[:page]).per_page(PAGE_SIZE)
    end

    def edit
      @transaction_count = @user.transactions.count
      @transaction_sum = Transaction.convert_to_dollars(@user.successful_transactions.sum(:amount_in_cents))
    end

    def import
      begin
        if params && params['csv'] && params['csv'].content_type == 'text/csv'
          reader = UserCsvFileReader.new
          uploaded_csv = reader.csv_rows_to_array(params['csv'].path.to_s)
          validator = UserImportValidator.new(uploaded_csv)
          validator.validate!
          filename = "#{DateTime.now.to_s(:number)}-#{params['csv'].original_filename}"
          headers['Content-Type'] = 'text/csv'
          headers['Content-disposition'] = "attachment; filename=#{filename}"
          self.response_body = UserCsvFileImporter.new(uploaded_csv, params)
        else
          raise Exception.new(msg = 'Invalid file type, please upload a .csv file.')
        end
      rescue Exception => e
        flash[:error] = e.message
        render :show_import
      end
    end

    def download_template_file
      send_data AppConstants.user_import_csv_headers, :type => 'text/csv', :filename => 'user-import-template.csv'
    end

    def download_country_iso_file
      countries = CSV.generate { |csv| Country.select_options.each { |country| csv << country } }
      send_data countries, :type => 'text/csv', :filename => 'country_iso_codes.csv'
    end

    private

    def handle_external_action_response(flash_errors, page_id, list)
      if flash_errors.blank?
        page = Page.find(page_id)
        if page.page_sequence.quarantined?
          Delayed::Job.enqueue(QuarantineJob.new(list, page))
        else
          Delayed::Job.enqueue(AddExternalActionsJob.new(list, page))
        end

        response_json = {:error => nil, :page_path => edit_admin_page_path(page_id)}
        respond_to do |format|
          format.json { render json: response_json.to_json }
        end
      else
        response_json = {:error => flash_errors, :page_path => nil}
        respond_to do |format|
          format.json { render json: response_json.to_json }
        end
      end
    end

    def create_new_page(params)
      campaign_id = params[:campaign_id]
      page_sequence_name = params[:page_sequence_name]
      page_name = params[:page_name]
      member_value_type = params[:member_value_type]

      campaign = Campaign.find(campaign_id)
      page_sequence = PageSequence.create!(name: page_sequence_name, campaign: campaign, facebook_image: "http://#{AppConstants.host}/images/getup_logo.png")
      Page.create!(name: page_name, page_sequence: page_sequence, member_value_type: member_value_type)
    end

    MAX_EXTERNAL_ACTION_IMPORT_SIZE = 100_000

    def validate_external_action_params(list, page_id)
      page = Page.find_by_id page_id
      return { :external_action_page_id => "Cannot find page id: #{page_id}" } if !page
      return { :external_action_page_id => "List too big to import" } if list.latest_user_count > MAX_EXTERNAL_ACTION_IMPORT_SIZE
      return { :external_action_page_id => "Please edit the page and set the 'ask category' first." } if page.member_value_type.blank?
      return {}
    end

    def validate_new_page_external_action_params(list, params)
      validation_errors = {}
      page_name = params[:page_name]
      page_sequence_name = params[:page_sequence_name]

      validation_errors[:page_name] = 'Page must have a name set' if page_name.blank?
      validation_errors[:page_sequence_name] = 'Page must have a page sequence' if page_sequence_name.blank?
      validation_errors[:page_sequence_name] = 'Page sequence already exists' if PageSequence.find_by_name(page_sequence_name)

      validation_errors[:external_action_page_id] = 'List too big to import' if list.latest_user_count > MAX_EXTERNAL_ACTION_IMPORT_SIZE

      validation_errors
    end

    def authorize_role_changes
      unless can? :change_roles, User
        if params[:user][:is_admin] || params[:user][:is_volunteer]
          raise CanCan::AccessDenied.new("Cannot change user roles!", :change_roles, User)
        end
      end
    end
  end
end
