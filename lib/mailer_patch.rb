module RedmineHelpdesk
  module MailerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method_chain :issue_edit,  :helpdesk
      end
    end

    module InstanceMethods
      # Overrides the issue_edit method which is only
      # be called on existing tickets. We will add the
      # owner-email to the recipients only if no email-
      # footer text is available.
      def issue_edit_with_helpdesk(journal, to_users=[], cc_users=[])
        
        other_recipients = []
        # add owner-email to the recipients
        begin
          if journal.send_to_owner == true
            issue = journal.journalized
            f = CustomField.find_by_name('helpdesk-email-footer')
            p = issue.project
            owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
            if !owner_email.blank? && !f.nil? && !p.nil? && p.custom_value_for(f).try(:value).blank?
              other_recipients << owner_email
            end
          end
        rescue Exception => e
          mylogger.error "Error while adding owner-email to recipients of email notification: \"#{e.message}\"."
        end

	issue_edit_without_helpdesk(journal, to_users, cc_users + other_recipients)
      end
      
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
