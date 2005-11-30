ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {process_task_id:integer,multiple}
    {confirm_p:boolean 0}
    {status_id:integer ""}
    {assignee_id:integer,optional}
    {process_id:integer,notnull}
    {orderby ""}
}


set num_entries [llength $process_task_id]


if { [string is false $confirm_p] } {

    if { $num_entries == 0 } {
	ad_returnredirect ./
	return
    }
    set title "Delete [ad_decode $num_entries 1 "a Process Task" "Process Tasks"]"
    set context [list $title]
    set question "Are you sure you want to delete [ad_decode $num_entries 1 "this process task" "these $num_entries process tasks"]?"
    set yes_url [export_vars -base process-task-delete -url { process_task_id:multiple { confirm_p 1 } assignee_id status_id orderby process_id }]                                                    
    set no_url [export_vars -base process -url { process_id assignee_id status_id orderby }]
    return
}

set user_id [ad_conn user_id]

set task_titles [list]

db_transaction {
    foreach process_task_id $process_task_id {
	lappend task_titles [db_string get_task_title {
	    select title
              from t_process_tasks
             where task_id = :process_task_id
               and process_id = :process_id
	}]
	db_dml mark_delete {
	    update t_process_tasks
            set status_id = null
	    where task_id = :process_task_id
	}
    }
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
    util_user_message -html -message "The process tasks ${task_list} were deleted"
} else {
    util_user_message -html -message "The process task \"[lindex $task_titles 0]\" was deleted"
}

ad_returnredirect [export_vars -base process -url { process_id assignee_id status_id orderby }]
ad_script_abort
