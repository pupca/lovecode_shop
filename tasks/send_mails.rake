task :send_emails, [:version] => [:environment] do |_, args|
	Signup.where("created_at < ? AND welcome_email_sent_at IS NULL", Time.now - Signup.send_welcome_mail_in_hours).each do |signup|
		puts "Sending welcome mail to #{signup.email}"
		signup.send_welcome_mail
	end

	Signup.where("created_at < ? AND invite_email_sent_at IS NULL", Time.now - Signup.send_invite_mail_in_hours).each do |signup|
		puts "Sending invite mail to #{signup.email}"
		signup.send_invite_email
	end

end