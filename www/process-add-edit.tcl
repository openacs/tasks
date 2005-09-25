ad_page_contract {

    Simple add/edit form for processs

    @author jader@bread.com
    @creation-date 2003-09-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.
} {
    process_id:integer,optional
    assignee_id:integer,optional
} -properties {
    context_bar:onevalue
    title:onevalue
}

set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

if { ![ad_form_new_p -key process_id] } {
    set process [db_string process_get { select title from t_processes where process_id = :process_id}]
    set title "Edit: $process"
    set context [list [list "processes" Processes] [list [export_vars -base "process" -url {process_id}] $process] "Edit"]
    # permissions
    permission::require_permission -party_id $user_id -object_id $package_id -privilege write
} else {
    set title "Add a Process"
    set context [list [list "processes" Processes] $title]
    # permissions
    permission::require_permission -party_id $user_id -object_id $package_id -privilege create
}


ad_form -name add_edit -form {
    process_id:key
    assignee_id:text(hidden),optional
    workflow_id:text(hidden),optional

    {title:text
        {label "Process"}
        {html {size 80}}
    }

    {description:text(textarea),optional
	{label "Description"}
	{html { rows 5 cols 40 wrap soft}}}

} -select_query_name process_query -new_data {

    db_transaction {
	set workflow_id [workflow::new \
			     -short_name "tasks_process_$process_id" \
			     -pretty_name "tasks process $process_id" \
			     -package_key tasks]

	set state_id [workflow::state::fsm::new \
			  -workflow_id $workflow_id \
			  -short_name new \
			  -pretty_name New]

	workflow::action::fsm::new \
	    -workflow_id $workflow_id \
	    -short_name new \
	    -pretty_name New \
	    -new_state_id $state_id \
	    -callbacks "tasks.Tasks_Action_SideEffect" \
	    -initial_action_p t

	set process_id [tasks::process::new \
			    -process_id $process_id \
			    -title $title \
			    -description $description \
			    -mime_type "text/plain" \
			    -workflow_id $workflow_id]
    }

    ad_returnredirect -message "Process added. Now add a process task." [export_vars -base process-task -url {process_id assignee_id}]
    ad_script_abort

} -edit_data {

    tasks::process::edit \
	-process_id $process_id \
	-title $title \
	-description $description \
	-mime_type "text/plain"

} -after_submit {

    ad_returnredirect -message "Process changes saved." [export_vars -base process -url {process_id assignee_id}]
    ad_script_abort
}
