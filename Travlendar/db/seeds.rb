# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

######################################################################################################

# DUMP EVERYTHING BEFORE RE-SEEDING
ActiveRecord::Base.establish_connection
ActiveRecord::Base.connection.tables.each do |table|
  next if table == 'schema_migrations'

  # MySQL and PostgreSQL
  ActiveRecord::Base.connection.execute("TRUNCATE #{table} RESTART IDENTITY CASCADE")

  # SQLite
  # ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
end
# DUMP EVERYTHING BEFORE RE-SEEDING

NUM_GROUPS = 3
NUM_SOCIALS = 4
NUM_EMAILS_PER_USER = 2
#NUM_BREAKS_PER_USER = 2
#NUM_STATUSES_PER_USER = 2
NUM_CONTACTS_PER_USER = 3
NUM_BREAKS_PER_USER = 1
NUM_USERS = 10
NUM_MEETINGS = 4
NUM_CATEGORIES = 10
NUM_LOCATIONS = 5
NUM_TRAVELS = 5
NUM_SUBJECTS = 5
NUM_OPERATORS = 4
NUM_VALUES = 10
NUM_CONSTRAINTS = 15
NUM_TRAVEL_MEANS = 4
MAX_DISTANCE = 20

for i in 1..NUM_GROUPS do
	Group.create({name: 'Group' + i.to_s})
end

for i in 1..NUM_SOCIALS do
	Social.create({name: 'Social' + i.to_s, icon_path: 'app/assets/images/social_icons/linkedin_icon.png'})
end

for i in 1..NUM_USERS do
	user = User.new({name: 'Pinco' + i.to_s, surname: 'Pallo' + i.to_s, password: '0000', nickname: 'PP' + i.to_s, preference_list: '1302'})
	user.groups.push(Group.find(i % NUM_GROUPS + 1))
	SocialUser.create({social_id: Social.find(i % NUM_SOCIALS + 1).id, link: 'www.linkedin.com/PincoPallo' + i.to_s, user_id: user.id})
	
	for j in 1..NUM_EMAILS_PER_USER do
		email = Email.create({email: 'Pinco' + i.to_s + '.Pallo.' + j.to_s + '@travlendar.com', user_id: i})
		user.emails.push(email)
	end

	for j in 1..NUM_BREAKS_PER_USER do
		start_time_slot = (j * 100) % (24 * 60)	# represented in minutes after midnight
		end_time_slot = (j * 200) % (24 * 60)	# represented in minutes after midnight
		default_time = (start_time_slot + end_time_slot) / 2
		duration = (end_time_slot - start_time_slot) / 10
		b = Break.create({default_time: default_time, start_time_slot: start_time_slot, end_time_slot: end_time_slot,
			duration: duration, name: 'Break' + j.to_s, day_of_the_week: j % 7, user_id: i})
	end
	primary_email = Email.create({email: 'Pinco' + i.to_s + '.Pallo@travlendar.com', user_id: i})
	puts(primary_email)
	user.primary_email_id = primary_email.id
	
	unless user.save()
		user.errors.full_messages.each do |message|
			puts(message)
		end
	end
end


for i in 1..NUM_USERS do
	user = User.find(i)
	for k in 1..NUM_CONTACTS_PER_USER do
		j = rand(1..NUM_USERS)
		while j == k do
			j = rand(1..NUM_USERS)
		end
		user.contacts.push(User.find(j))
	end
end

location = Location.create({latitude: 37.4133028, longitude: -122.1513074, description: "Mountain View"})

for i in 1..NUM_MEETINGS do
	new_start_date = DateTime.new(2017, i % 12, i % 28, 12, 35, 0)
	end_date = DateTime.new(2017, i % 12, i % 28, 14, 35, 0)
	meeting = Meeting.create({location_id: location.id, title: 'NewMeeting' + i.to_s, start_date: new_start_date, end_date: end_date})
end

for i in 1..NUM_TRAVELS do
	starting_datetime = DateTime.new(2017, i % 12, i % 28, (10+i) % 24, 35, 0)
	ending_datetime = DateTime.new(2017, i % 12, i % 28, (11+i) % 24, 35, 0)
	travel_mean_used = rand(1..NUM_TRAVEL_MEANS)
	distance = rand() * MAX_DISTANCE
	Travel.create({start_time: starting_datetime, end_time: ending_datetime, travel_mean: travel_mean_used, distance: distance})
end

for i in 1..NUM_USERS do
	for j in 1..NUM_MEETINGS do
		k = rand(1..10)
		if k > 8
			MeetingParticipation.create({meeting_id: Meeting.find(j % NUM_MEETINGS + 1).id, user_id: User.find(i % NUM_USERS + 1).id, is_consistent: true, 
				arriving_travel_id: Travel.find(i % NUM_TRAVELS + 1).id, leaving_travel_id: Travel.find((i+1) % NUM_TRAVELS + 1).id})
		end
	end
end

for i in 1..NUM_LOCATIONS do
	r1 = rand(-179..179)
	r2 = rand(-179..179)
	Location.create({latitude: r1, longitude: r2, description: 'location with coordinates ' + r1.to_s + " " + r2.to_s})
end

for i in 1..NUM_CATEGORIES do
  cat = Category.create({name: 'category' + i.to_s, superclass_id: 1})
end

for i in 1..NUM_CATEGORIES do
	j = rand(1..NUM_CATEGORIES)
	while j == i do
		j = rand(1..NUM_CATEGORIES)
	end
	Category.find(i).superclass_id = Category.find(j).id
end

for i in 1..NUM_SUBJECTS do
	subject = Subject.create({name: "Subject" + i.to_s})
end

for i in 1..NUM_OPERATORS do
	operator = Operator.create({description: "Operator" + i.to_s, subject_id: Subject.find(i % NUM_SUBJECTS + 1).id, operator: i})	
end

for i in 1..NUM_VALUES do
	value = Value.create({value: "Value" + i.to_s, subject_id: Subject.find(i % NUM_SUBJECTS + 1).id})	
end 

for i in 1..NUM_CONSTRAINTS do
	travel_mean_used = rand(1..NUM_TRAVEL_MEANS)
	Constraint.create({travel_mean: travel_mean_used, user_id: User.find(i % NUM_USERS + 1).id, subject_id: Subject.find(i % NUM_SUBJECTS + 1).id, 
		operator_id: Operator.find(i % NUM_OPERATORS + 1).id, value_id: Value.find(i % NUM_VALUES + 1).id})
end