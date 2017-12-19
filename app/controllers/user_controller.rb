class UserController < ApplicationController
	skip_before_action :require_login
	wrap_parameters :user, include: [:nickname, :password, :password_confirmation]

	def show
		require_login
		@user = User.find(params[:id])

	end

	def my_user_page
		@user = current_user
	end

	def create
		# problems on create user before email and viceversa

		email_hash = params.slice(:user)['user']['email']
		params[:user].delete('email')

		incomplete_user = IncompleteUser.find(session[:tmp_checked])
		incomplete_user_email = incomplete_user.email
		incomplete_user_psw = incomplete_user.password

		@user = User.new(user_params)
		unless email_hash == incomplete_user_email && incomplete_user.authenticate(@user.password)
			flash.now[:danger] = 'Wrong mail or password'
			@unregistered_user = incomplete_user
			render 'new'
			return
		end

		if @user.valid?
			session[:tmp_checked] = nil # delete temp variable
			IncompleteUser.delete(incomplete_user.id)
			email = Email.create(email: email_hash)
			@user.emails.push(email)
			@user.primary_email_id = email.id
			last_user = User.last
			email.user_id = User.last.id + 1
			@user.save
			log_in @user
			redirect_to calendar_day_path DateTime.now.year, DateTime.now.month, DateTime.now.day
		else
			@unregistered_user = incomplete_user
			render 'new'
		end
	end

	def new
		@unregistered_user = IncompleteUser.find(session[:tmp_checked])
		@user = User.new
		@user.preference_list = '0123'
	end

	def index
		respond_to do |format|
			format.html {html_index}
			format.json {json_index}
		end
	end

	def contacts
		@user = current_user
		puts ("ncjkdscnkdsjcnsdkj")
		puts (@user.id)
		puts(params[:id])
		check_if_myself
		@contacts = @user.contacts
	end

	def delete_contact
		contact_delate_check(params[:user_id], params[:to_delete_id])
		Contact.delete(Contact.where(from_user: params[:user_id], to_user: params[:to_delete_id]))
		redirect_to contacts_page_path(id: params[:user_id])
	end

	def add_contact
		contact_add_check(params[:user_id], params[:to_add_id])
		current_user.contacts.push(User.find(params[:to_add_id]))
		redirect_to contacts_page_path(id: params[:user_id])
	end

	def search
		if params[:term]
			to_match = '%' + params[:term] + '%'
			@users = User.where("(name ILIKE :search OR surname ILIKE :search OR nickname ILIKE :search) AND id != :current_id", search: to_match, current_id: current_user.id)
		else
			@users = User.all
		end

		respond_to do |format|
			format.html # new.html.erb
			format.json {render :json => @users.to_json}
		end
	end

	def search_contacts
		if params[:term]
			to_match = '%' + params[:term] + '%'
			user = current_user
			@users = User.where("(name ILIKE :search OR surname ILIKE :search OR nickname ILIKE :search) AND
					id != :current_id AND id NOT IN (:contacts)", search: to_match, current_id: user.id, contacts: user.contacts.all.ids)
		else
			@users = User.all
		end

		respond_to do |format|
			format.html # new.html.erb
			format.json {render :json => @users.to_json}
		end
	end

	def settings
		check_if_myself
		@user = current_user
	end

	def change_preference_list
		check_if_myself
		user = current_user
		user.update_attributes(user_pref_list_params)
		user.save
		redirect_to settings_page_path
	end

	def user_pref_list_params
		params.require(:user).permit(:preference_list)
	end

	def delate_constraint
		delete_constraint_check(params[:user_id], params[:constraint_id])
		Constraint.delete(params[:constraint_id])
		redirect_to settings_page_path(id: params[:user_id])
	end

	def add_constraint
		@constraint = Constraint.new
		@operators = Operator.all
		@values = Value.all
	end

	def create_constraint
		travel_mean = params[:constraint][:travel_mean]
		subject = Subject.find(params[:constraint][:subject].to_i)
		operator = Operator.find_by(description: params[:constraint][:operator])
		value = Value.find_by(value: params[:constraint][:value])
		c = Constraint.new({travel_mean: travel_mean, subject: subject, operator: operator, value: value, user: current_user})
		if c.valid?
			c.save
			redirect_to settings_page_path
		else
			render 'add_constraint'
		end
	end


	private

	def html_index
		@users = User.all
	end

	def json_index
		query = begin
			params.permit(:query).fetch(:query)
		rescue
			''
		end
		users = User.where('LOWER(nickname) LIKE LOWER(:query)', query: "%#{query}%")
		render json: users.map(&:name)
	end

	def user_params
		params.require(:user).permit(:name, :surname, :password, :nickname, :preference_list)
	end

	def reinsertUser(incomplete_user_email, incomplete_user_psw)
		IncompleteUser.create(email: incomplete_user_email, password: incomplete_user_psw, password_confirmation: incomplete_user_psw)
	end

	def check_if_myself(id = params[:id].to_i)
		unless current_user.id == id
			raise ActionController::RoutingError, 'Not Found'
		end
	end

	def contact_delate_check(user, action_user)
		unless (current_user.id == user.to_i) && (current_user.contacts.where(id: action_user).count() > 0)
			raise ActionController::RoutingError, 'Not Found'
		end
	end

	def contact_add_check(user, action_user)
		unless (current_user.id == user.to_i) && (current_user.contacts.where(id: action_user).count() == 0)
			raise ActionController::RoutingError, 'Not Found'
		end
	end

	def delete_constraint_check(user, constraint)
		unless (current_user.id == user.to_i) && (current_user.constraints.where(id: constraint).count() > 0)
			raise ActionController::RoutingError, 'Not Found'
		end
	end

	def check_constraint_params
		params.require(:constraint).permit(:travel_mean, :subject, :operator, :value)
	end
end
