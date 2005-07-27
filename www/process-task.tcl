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
    status_id:integer,optional
    orderby:optional
} -properties {
} -validate {
    valid_process_id -requires process_id {
	if { ![db_0or1row process_exists_p { select 1 from pm_process where process_id = :process_id}] } {
	    ad_complain "The process_id specified is not valid"
	}
    }
    valid_party_id -requires process_id {
	set process_owner [db_string process_manager { select party_id from pm_process where process_id = :process_id}]
	if { $process_owner != [ad_conn user_id] || ![permission::permission_p -object_id [ad_conn package_id] -privilege admin] } {
		ad_complain "The process specified belongs to [db_string process_manager { select person__name(party_id) from pm_process where process_id = :process_id}]. Please ask that person or a website administrator to edit tasks on this process or assign it to you so you can manage it."
	}
    }
}



set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]
set project_id [tasks::project_id]
set process    [db_string process_get { select one_line from pm_process where process_id = :process_id}]

if { [ad_form_new_p -key process_task_id] } {
    set title "Add Process Task"
    set edit_buttons {
	{Save save}
        {{Save and Add Another} save_add_another}
    }
} else {
    set title "Edit: "
    append title [db_string get_task_name {
	    select pm.one_line
              from pm_process_task pm
             where pm.process_task_id = :process_task_id
               and pm.process_id = :process_id
    }]
    append edit_buttons {
	{Update save}
        {{Update and Add New Task} save_add_another}
        {{Delete} delete}
    }
}
set context [list [list "processes" Processes] [list [export_vars -base "process" -url {process_id}] $process] $title]



if { [ns_queryget "formbutton:delete"] != "" } {
    ad_returnredirect [export_vars -base "process-task-delete" -url {process_id process_task_id status_id orderby}]
    ad_script_abort
}

ad_form -name add_edit \
    -cancel_url [export_vars -base "process" -url {process_id}] \
    -cancel_label "Cancel" \
    -edit_buttons $edit_buttons \
    -form {
        process_task_id:key
        process_id:integer(hidden)

        status_id:integer(hidden),optional
        orderby:text(hidden),optional


        {task:text(text)
            {label "Process Task"}
            {html { size 28 maxlength 50}}
	}
        
    {due_date:text(text),optional
        {label "Default Hard Deadline"}
	{html {id date1 size 10 maxlength 10}}
        {help_text {if blank there is no default deadline}}
	{after_html {
<button type=\"reset\" id=\"f_date_b1\">YYYY-MM-DD</button>
<script type=\"text/javascript\">
    Calendar.setup({
        inputField     :    \"date1\",       // id of the input field, put readonly 1 in html to limit input 
        ifFormat       :    \"%Y-%m-%d\",   // Format the input field
        daFormat       :    \"%m %d %Y\",   // Format for the display area
        showsTime      :    false,          // will display a time selector
        button         :    \"f_date_b1\",   // trigger for the calendar (button ID)
        singleClick    :    true,           // double-click mode
        step           :    1,              // show all years in drop-down boxes (instead of every other year as default)
        weekNumbers    :    false,          // do not show the week numbers
        showOthers     :    false           // show days belonging to other months
    });
</script>
	}}}
    

        {due_days:integer(text),optional
            {label "Default Variable Deadline"}
            {html {size 3 maxlength 3}}
            {help_text {Variable deadlines that fall on Saturday or Sunday will automatically be pushed to the next Monday}}
            {after_html {days after assignment}}
        }

        {priority:integer(select),optional
            {label "Priority"}
            {options {{{3 - Very Important} 3} {{2 - Important} 2} {{1 - Normal} 1} {{0 - Not Important} 0}}}
        }

        {description:text(textarea),optional,nospell
            {label "Notes"}
            {html { rows 5 cols 50 wrap soft}}}

    } \
    -new_request {

	set status_id "1"
        set priority "1"

    } -edit_request {

	db_1row get_task_info {
	    select pm.one_line as task,
                   pm.description,
                   tp.due_interval,
                   tp.due_date,
                   tp.priority
              from pm_process_task pm,
                   tasks_pm_process_task tp
             where pm.process_task_id = :process_task_id
               and pm.process_id = :process_id
               and pm.process_task_id = tp.process_task_id
     	}
	set due_days [lindex $due_interval 0]

    } -validate {
	{due_date 
	    {[calendar::date_valid_p -date $due_date]}
	    {This is not a valid date. Either the date doesn't exist or it is not formatted correctly. Correct formatting is: YYYY-MM-DD or YYYYMMDD}
	}
	{due_date
	    { [expr \
	          [expr [string equal $due_date ""] == 1 && [string equal [string trim $due_days] ""] == 1] || \
		  [expr [string equal $due_date ""] == 1 && [string equal [string trim $due_days] ""] == 0] || \
		  [expr [string equal $due_date ""] == 0 && [string equal [string trim $due_days] ""] == 1]
	      ]}
	    {You may either use a Hard Deadline, a Variable Deadline or neither but not both}
	}
	{due_days
	    { [expr \
	          [expr [string equal $due_date ""] == 1 && [string equal [string trim $due_days] ""] == 1] || \
		  [expr [string equal $due_date ""] == 1 && [string equal [string trim $due_days] ""] == 0] || \
		  [expr [string equal $due_date ""] == 0 && [string equal [string trim $due_days] ""] == 1]
	      ]}
	    {You may either use a Hard Deadline, a Variable Deadline or neither but not both}
	}
    } -on_submit {
        set user_id [ad_conn user_id]
        set peeraddr [ad_conn peeraddr]
	if { [exists_and_not_null due_days] } {
	    set due_interval "${due_days} days"
	} else {
	    set due_interval ""
	}
	set process_task_url [export_vars -base "/tasks/process-task" -url {process_id process_task_id}]
    } -new_data {
	db_transaction {
	    db_dml insert_pm_process_task {
		insert into pm_process_task
                ( process_task_id, process_id, one_line, description, mime_type )
		values
		( :process_task_id, :process_id, :task, :description, 'text/plain' )
	    }
	    db_dml insert_tasks_pm_process_task {
		insert into tasks_pm_process_task
                ( process_task_id, due_interval, due_date, priority )
		values
                ( :process_task_id, :due_interval, :due_date, :priority )
	    }
	    util_user_message -html -message "The process task <a href=\"${process_task_url}\">$task</a> was added"
	}


    } -edit_data {
	db_transaction {
	    db_dml update_pm_process_task {
		update pm_process_task
                   set one_line = :task,
		       description = :description
                 where process_task_id = :process_task_id
                   and process_id = :process_id
	    }
	    db_dml update_tasks_pm_process_task {
		update tasks_pm_process_task
                   set due_interval = :due_interval,
		       due_date = :due_date,
                       priority = :priority
                 where process_task_id = :process_task_id
	    }
	    util_user_message -html -message "The process task <a href=\"${process_task_url}\">$task</a> was updated"
	}

    } -after_submit {

	if { [ns_queryget "formbutton:save_add_another"] != "" } {
	    set return_url [export_vars -url -base "process-task" {process_id}]
	} else {
	    set return_url [export_vars -url -base "process" {process_id}]
	}
	ad_returnredirect $return_url
	ad_script_abort

    }

