ad_page_contract {

    Simple add/edit form for projects

    @author jader@bread.com, ncarroll@ee.usyd.edu.au
    @creation-date 2003-05-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.

} {
    process_id:integer,notnull
    process_task_id:integer,optional
    assignee_id:integer,optional
    status_id:integer,optional
    orderby:optional
} -properties {
} -validate {
    valid_process_id -requires process_id {
	if { ![db_0or1row process_exists_p { select 1 from t_processes where process_id = :process_id}] } {
	    ad_complain "The process_id specified is not valid"
	}
    }
}

tasks::require_belong_to_package -objects $process_id

set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]
db_1row process_get {
    select title as process, workflow_id
    from t_processes
    where process_id = :process_id
}

if { [ad_form_new_p -key process_task_id] } {
    set title "Add Process Task"
    set edit_buttons {
	{Save save}
        {{Save and Add Another} save_add_another}
    }
} else {
    set title "Edit: "
    append title [db_string get_task_name {
	    select title
              from t_process_tasks
             where task_id = :process_task_id
    }]
    append edit_buttons {
	{Update save}
        {{Update and Add New Task} save_add_another}
        {{Delete} delete}
    }
}
set context [list [list "processes" Processes] [list [export_vars -base "process" -url {process_id assignee_id}] $process] $title]

set status_options [db_list_of_lists status_options {
    select title, status_id
    from t_task_status
    order by status_id
}]
set status_options [lang::util::localize $status_options]

set open_options [db_list_of_lists open_action_options {
    select title, closing_action_id
    from t_process_tasks
    where process_id = :process_id
    and status_id is not null
    order by lower(title)
}]
set open_options [concat [list [list "-- new --" ""]] $open_options]

if { [ns_queryget "formbutton:delete"] != "" } {
    ad_returnredirect [export_vars -base "process-task-delete" -url {process_id process_task_id assignee_id status_id orderby}]
    ad_script_abort
}

ad_form -name add_edit \
    -cancel_url [export_vars -base "process" -url {process_id assignee_id}] \
    -cancel_label "Cancel" \
    -edit_buttons $edit_buttons \
    -form {
        process_task_id:key
        process_id:integer(hidden)
        workflow_id:integer(hidden)

        assignee_id:integer(hidden),optional
        status_id:integer(hidden),optional
        orderby:text(hidden),optional

        {task:text(text)
            {label "Process Task"}
            {html { size 80 maxlength 200}}
	}
        
        {status:text(select)
            {label "[_ tasks.Status]"}
            {options $status_options}
        }

        {priority:integer(select),optional
            {label "Priority"}
            {options {{{3 - Very Important} 3} {{2 - Important} 2} {{1 - Normal} 1} {{0 - Not Important} 0}}}
        }

        {open_action_id:integer(select),optional
            {label "After"}
            {options $open_options}
        }

        {description:text(textarea),optional,nospell
            {label "Notes"}
            {html { rows 5 cols 50 wrap soft}}}

        {comment:text(textarea),optional,nospell
            {label "[_ tasks.Comment]"}
            {html { rows 5 cols 50 wrap soft}}}

        {start:integer(text),optional
            {label "Variable Start"}
            {html {size 3 maxlength 3}}
            {help_text {Variable start that fall on Saturday or Sunday will automatically be pushed to the next Monday}}
            {after_html {days after assignment}}
        }

        {due:integer(text),optional
            {label "Variable Deadline"}
            {html {size 3 maxlength 3}}
            {help_text {Variable deadlines that fall on Saturday or Sunday will automatically be pushed to the next Monday}}
            {after_html {days after assignment}}
        }

    } \
    -new_request {

	set status "1"
        set priority "1"
	set start 0
	set due 0

    } -edit_request {

	db_1row get_task_info {
	    select title as task, description, status_id as status, priority,
	           start, due, comment, open_action_id
              from t_process_tasks
             where task_id = :process_task_id
               and process_id = :process_id
     	}

    } -on_submit {
	set process_task_url [export_vars -base "/tasks/process-task" -url {process_id process_task_id assignee_id}]
    } -new_data {
	db_transaction {

	    set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name new]
	    
	    set closing_action_id [workflow::action::fsm::new \
				       -workflow_id $workflow_id \
				       -short_name "tasks_action_$process_task_id" \
				       -pretty_name "task action $process_task_id" \
				       -enabled_state_ids $state_id \
				       -new_state_id $state_id \
				       -callbacks "tasks.Tasks_Action_SideEffect"]

	    if {[empty_string_p $open_action_id]} {
		set open_action_id [workflow::action::get_id -workflow_id $workflow_id -short_name new]
	    }

	    set process_task_id [tasks::process::task::new \
				     -task_id $process_task_id \
				     -process_id $process_id \
				     -open_action_id $open_action_id \
				     -closing_action_id $closing_action_id \
				     -title $task \
				     -description $description \
				     -mime_type "text/plain" \
				     -comment $comment \
				     -status_id $status \
				     -priority $priority \
				     -start $start \
				     -due $due \
				     -assignee_id $assignee_id]

	    util_user_message -html -message "The process task <a href=\"${process_task_url}\">$task</a> was added"
	}


    } -edit_data {

    tasks::process::task::edit \
	-task_id $process_task_id \
	-open_action_id $open_action_id \
	-title $task \
	-description $description \
	-mime_type "text/plain" \
	-comment $comment \
	-status_id $status \
	-priority $priority \
	-start $start \
	-due $due \
	-assignee_id $assignee_id

    util_user_message -html -message "The process task <a href=\"${process_task_url}\">$task</a> was updated"

    } -after_submit {

	if { [ns_queryget "formbutton:save_add_another"] != "" } {
	    set return_url [export_vars -url -base "process-task" {process_id assignee_id}]
	} else {
	    set return_url [export_vars -url -base "process" {process_id assignee_id}]
	}
	ad_returnredirect $return_url
	ad_script_abort

    }

