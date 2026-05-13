class ProjectManagementsController < ApplicationController
  before_action :set_order, only: :show

  def index
    @orders = current_company.orders
                             .includes(:customer, :order_status, :project_tasks, :project_issues, :assignments)
                             .order(created_at: :desc)

    if params[:customer_name].present?
      @orders = @orders.joins(:customer).where("customers.name LIKE ?", "%#{params[:customer_name]}%")
    end

    if params[:project_name].present?
      @orders = @orders.where("orders.project_name LIKE ?", "%#{params[:project_name]}%")
    end

    if params[:status].present?
      @orders = @orders.joins(:order_status).where(order_statuses: { code: params[:status] })
    end

    @total_count = @orders.count
    @orders = @orders.page(params[:page]).per(20)
    @order_statuses = OrderStatus.where(is_active: true)
  end

  def show
    load_project_management
    load_document_counts
  end

  private

  def set_order
    @order = current_company.orders.with_discarded.includes(:customer, :order_status, :histories, :payment_records).find(params[:id])
  end

  def load_project_management
    @project_phase_tasks = @order.project_tasks.phases.includes(:assignee, :subtasks).ordered
    @project_detail_tasks = @order.project_tasks.details.includes(:assignee, :parent).ordered
    @project_tasks = @order.project_tasks.includes(:assignee, :parent).ordered
    @project_issues = @order.project_issues.includes(:assignee).ordered
    @assignments = @order.assignments.includes(:user).order(:role, :id)
    @company_users = current_company.users.active.order(:name, :email)
    @new_project_phase = @order.project_tasks.build(start_date: Date.current, due_date: Date.current + 7.days)
    @new_project_task = @order.project_tasks.build(start_date: Date.current, due_date: Date.current + 2.days)
    @new_project_issue = @order.project_issues.build
    @new_assignment = @order.assignments.build
  end

  def load_document_counts
    customer_name = @order.customer&.name
    subject = @order.project_name.presence || @order.display_order_number

    @document_counts = {
      quotations: document_count(Quotation, customer_name, subject),
      delivery_notes: document_count(DeliveryNote, customer_name, subject),
      invoices: document_count(Invoice, customer_name, subject),
      receipts: document_count(Receipt, customer_name, subject)
    }
  end

  def document_count(model, customer_name, subject)
    scope = model.where(company: current_company)
    return scope.where("subject LIKE ?", "%#{subject}%").count if subject.present?
    return scope.where(customer_name: customer_name).count if customer_name.present?

    0
  end
end
