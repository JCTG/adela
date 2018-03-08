module Admin
  class UsersController < Admin::BaseController
    load_and_authorize_resource
    skip_authorize_resource only: :stop_acting

    has_scope :names, :email, :organization

    def index
      @users = apply_scopes(User).all.paginate(page: params[:page])
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      create_user_and_send_password(@user)
      if @user.new_record?
        render 'new'
      else      
        flash[:notice] = I18n.t('flash.notice.user.create')
        redirect_to admin_users_path
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        flash[:notice] = I18n.t('flash.notice.user.update')
        redirect_to admin_users_path        
      else
        render 'edit'
      end
    end

    def destroy
      user = User.find(params[:id])
      user.destroy
      flash[:notice] = I18n.t('flash.notice.user.deleted')
      redirect_to admin_users_path
    end

    def acting_as
      @user = User.find(params[:id])
      session[:from_admin] = true
      session[:original_user_id] = current_user.id
      sign_in(@user)
      redirect_to root_path
    end

    def stop_acting
      user = User.find(session[:original_user_id])
      session[:from_admin] = false
      session.delete(:original_user_id)
      sign_in(user)
      redirect_to admin_root_path
    end

    def create_users
      create_users_from_file(csv_file_uploader)
      if @users.any?
        flash[:notice] = I18n.t('flash.notice.user.import')
      else
        flash[:alert] = I18n.t('flash.alert.user.import')
      end
      redirect_to admin_users_path
    end

    def grant_admin_role
      user = User.find(params[:id])
      user.add_role :admin
      flash[:notice] = I18n.t('flash.notice.user.update_role')
      redirect_to admin_users_path
    end

    def remove_admin_role
      user = User.find(params[:id])
      user.remove_role :admin
      flash[:notice] = I18n.t('flash.notice.user.update_role')
      redirect_to admin_users_path
    end

    def edit_password
      @user = User.find(params[:id])
    end

    def update_password
      @user = User.find(params[:id])
      if @user.update(update_user_password_params)
        flash[:notice] = I18n.t('flash.notice.user.update_password')
        redirect_to admin_users_path
      else
        render 'edit_password'
      end
    end

    private

    def csv_file_uploader
      uploader = UsersUploader.new
      uploader.store!(file_params)
      uploader.read.to_utf8
    end

    def create_users_from_file(file_content)
      @users = []
      CSV.new(file_content, headers: :first_row).each do |row|
        user = build_user_from_csv(row)
        create_user_and_send_password(user)
        @users << user unless user.new_record?
      end
    end

    def build_user_from_csv(row)
      User.new do |user|
        user.name  = row['nombre']
        user.email = row['email']
        user.organization = first_or_initialize_organization_from_csv(row)
        user.organization.build_inventory
        user.organization.build_catalog
      end
    end

    def first_or_initialize_organization_from_csv(row)
      Organization.where(title: row['organizacion']).first_or_initialize
    end

    def create_user_and_send_password(user)
      password = Devise.friendly_token.first(8)
      user.password = password
      UserAccountWorker.perform_async(user.id, password) if user.save
    end

    def user_params
      params.require(:user).permit(:name, :email, :organization_id)
    end

    def update_user_password_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def file_params
      params.require(:csv_file)
    end
  end
end
