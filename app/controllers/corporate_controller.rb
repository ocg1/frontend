class CorporateController < ArticlesController
  before_action :authenticate, if: -> { Authenticable.required? }, only: :export_partners
  before_action :setup_category, only: %i[index enquiry_submit general_enquiry]
  decorates_assigned :article, with: CorporateDecorator
  decorates_assigned :category, with: CorporateCategoryDecorator

  def index; end

  def show
    @article = interactor.call do |error|
      if error.redirect?
        return redirect_to error.location, status: error.status
      else
        not_found
      end
    end

    set_breadcrumbs
    set_related_content
    set_categories

    retrieve_syndication_tools
    retrieve_corporate_category
    set_corporate_category
    assign_active_categories(retrieve_corporate_category)
    @partner = CorporatePartner.new
  end

  def create
    @partner = CorporatePartner.find_or_initialize_by(email: params[:corporate_partner][:email])
    @partner.assign_attributes(partner_params)
    @partner.tool_name = tool_friendly_name

    if @partner.save
      flash[:success] = t('tool_page.form.success_flash')
      flash[:partner] = @partner
      redirect_to corporate_path(params[:id], anchor: 'your-embed-code')
    else
      @article = interactor.call
      retrieve_corporate_category
      set_corporate_category
      assign_active_categories(retrieve_corporate_category)
      set_related_content
      render :show
    end
  end

  def export_partners
    @corporate_partners = CorporatePartner.all
    csv = @corporate_partners.to_csv
    send_data csv,
              type: 'text/csv; charset=iso-8859-1; header=present',
              disposition: 'attachment',
              filename: "corporate_partners-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"
  end

  def enquiry_submit
    @enquiry = GeneralEnquiry.new
    @enquiry.assign_attributes(params.require(:general_enquiry).permit(*GeneralEnquiry::ATTRIBUTES))
    if @enquiry.valid?
      #TODO: send enquiry to CRM
      #TODO: flash message should be translated
      return redirect_to(corporate_path('about-us'), flash: { info: 'message sent' })
    end
    render :general_enquiry
  end

  def general_enquiry
    @enquiry = GeneralEnquiry.new
  end

  private

  def setup_category
    @category = retrieve_corporate_category
    assign_active_categories(@category)
  end

  def retrieve_corporate_category
    @corporate_category ||= Core::CategoryReader.new('corporate-home').call
  end

  def set_corporate_category
    @category = @article.categories.last
  end

  def retrieve_syndication_tools
    @syndication_tools ||= Core::CategoryReader.new('syndication').call
  end

  def interactor
    Core::CorporateReader.new(params[:id])
  end

  def category_tree(categories)
    Core::CategoryTreeReader.new.call(categories)
  end

  def partner_params
    params.require(:corporate_partner).permit(:name, :email, :tool_language, :tool_width_unit, :tool_width)
  end

  def tool_friendly_name
    params[:id].chomp('-syndication').gsub('-', ' ').humanize
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      Authenticable.authenticate(username, password)
    end
  end
end
