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

tasks::require_belong_to_package -objects $task_id 

set num_entries [llength $task_id]

if { [string is false $confirm_p] } {

    if { $num_entries == 0 } {
	ad_returnredirect ./
	return
    }
    set pretty_task [ad_decode $num_entries 1 "[_ tasks.Task]" "[_ tasks.Tasks]"]
    set title "[_ tasks.Mark_Done]"
    set context [list $title]
    set pretty_entries [ad_decode $num_entries 1 "[_ tasks.this_task]" "[_ tasks.these_tasks]"]
    set question "[_ tasks.completed_sure]"
    set yes_url "mark-completed?[export_vars { task_id:multiple { confirm_p 1 } status_id orderby party_id}]"                                                    
    set no_url "./?[export_vars { status_id orderby party_id}]"
    return
}

set user_id [ad_conn user_id]

db_transaction {
    set task_titles [list]
    foreach task_id $task_id {
	set task_title [db_string get_task_title {
	    select t.title
	    from t_tasks t
	    where t.task_id = :task_id
	}]
	lappend task_titles "<a href=\"[export_vars -base "task" -url {task_id status_id orderby}]\">${task_title}</a>"

	tasks::task::complete -task_id $task_id
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
    util_user_message -html -message "[_ tasks.tasks_completed]"
} else {
    set task_title [lindex $task_titles 0]
    util_user_message -html -message "[_ tasks.task_completed]"
}

ad_returnredirect $return_url
ad_script_abort
