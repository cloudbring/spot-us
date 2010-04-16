class CcaController < ApplicationController
  before_filter :login_required
  before_filter :load_cca, :only => [:show]
  resources_controller_for :cca

  
  def show
  end
  
  def results
    @cca = find_resource
    respond_to do |format|
      format.html do
      end
      format.csv do
        send_data @cca.generate_csv, :type => 'text/csv; charset=iso-8859-1; header=present',
                              :disposition => "attachment; filename=results_#{@cca.to_param}.csv"
      end
    end
  end
  
  def submit_answers
	#debugger
    @cca = find_resource
    tos = params[:tos] || false
    Feedback.sponsor_interest(current_user) if params[:sponsor_interest] # process user signup for being a sponsor
    is_completed = @cca.process_answers(params[:answers], current_user)  # process the survey answers
    if is_completed && tos
      @cca.award_credit(current_user)
      update_balance_cookie
      redirect_to apply_credits_cca_path(@cca)
    elsif !tos                                                           # they need to check the TOS box on form
      flash[:error] = "You have to accept the terms of service to complete this survey."
      redirect_to :back
    else
      flash[:error] = "Please answer all questions to earn your credits."
      redirect_to :back
    end
  end 
  
  def apply_credits
    @cca = find_resource
    @filter = "almost-funded"
    @news_items = NewsItem.constrain_type(@filter).send(@filter.gsub('-','_')).order_results(@filter).browsable.by_network(current_network).paginate(:page => params[:page])
  end
  
  protected
  
  def load_cca
    @cca = Cca.find_by_id(params[:id])
    redirect_to root_url unless @cca && @cca.is_live? || current_user.admin?
  end
  
end
