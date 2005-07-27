ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {task_id:integer,multiple}
    {confirm_p:boolean 1}
    {return_url:notnull}
}


set num_entries [llength $task_id]
set user_id [ad_conn user_id]

if { [string is false $confirm_p] } {

    if { $num_entries == 0 } {
	ad_returnredirect ./
	return
    }
    set title "Delete [ad_decode $num_entries 1 "a Task" "Tasks"]"
    set context [list $title]
    set question "Are you sure you want to delete [ad_decode $num_entries 1 "this task" "these $num_entries tasks"]?"
    set yes_url "delete?[export_vars { task_id:multiple { confirm_p 1 } return_url}]"                                                    
    set no_url "${return_url}"
    return
}


set task_titles [list]
foreach task_id $task_id {
    lappend task_titles [db_string get_task_title {
	    select cr.title as task
              from pm_tasks_revisions ptr,
                   cr_revisions cr,
                   cr_items ci
             where ci.item_id = :task_id
               and ci.latest_revision = ptr.task_revision_id
               and ci.live_revision = ptr.task_revision_id
               and ptr.task_revision_id = cr.revision_id
            
    }]
    db_dml mark_delete "update pm_tasks set deleted_p = 't' where task_id = :task_id"
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
    util_user_message -html -message "The tasks ${task_list} were deleted"
} else {
    util_user_message -html -message "The task \"[lindex $task_titles 0]\" was deleted"
}

ad_returnredirect $return_url
ad_script_abort




