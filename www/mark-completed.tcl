ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {task_id:integer,multiple}
    {confirm_p:boolean 1}
    {status_id:integer ""}
    {orderby ""}
    {return_url:notnull}
}
#    {party_id:integer,notnull}

set num_entries [llength $task_id]

if { [string is false $confirm_p] } {

    if { $num_entries == 0 } {
	ad_returnredirect ./
	return
    }
    set title "Mark [ad_decode $num_entries 1 "Task" "Tasks"] as Done"
    set context [list $title]
    set question "Are you sure you want to mark [ad_decode $num_entries 1 "this task" "these $num_entries tasks"] as done?"
    set yes_url "mark-done?[export_vars { task_id:multiple { confirm_p 1 } status_id orderby party_id}]"                                                    
    set no_url "./?[export_vars { status_id orderby party_id}]"
    return
}

set user_id [ad_conn user_id]

set task_titles [list]
foreach task_id $task_id {
    set task_title [db_string get_task_title {
	    select cr.title as task
              from pm_tasks_revisions ptr,
                   cr_revisions cr,
                   cr_items ci
             where ci.item_id = :task_id
               and ci.latest_revision = ptr.task_revision_id
               and ci.live_revision = ptr.task_revision_id
               and ptr.task_revision_id = cr.revision_id
            
    }]
    lappend task_titles "<a href=\"[export_vars -base "task" -url {task_id status_id orderby}]\">${task_title}</a>"
    pm::task::update_percent -task_item_id $task_id -percent_complete "100"
}


if { $num_entries > 1 } {
    set task_list ""
    set num 1
    foreach task_title $task_titles {
	if { $num == $num_entries } {
	    append task_list " and "
	} elseif { $num != 1 } {
	    append task_list ", "
	}
	append task_list "\"${task_title}\""
	incr num
    }
    util_user_message -html -message "The tasks ${task_list} were marked done"
} else {
    util_user_message -html -message "The task \"[lindex $task_titles 0]\" was marked done"
}
#util_user_message -message "[ad_decode $num_entries 1 "One task" "$num_entries tasks"] marked done."

ad_returnredirect $return_url
ad_script_abort




