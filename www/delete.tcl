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
    set task_pretty [ad_decode $num_entries 1 "[_ tasks.Task]" "[_ tasks.Tasks]"]
    set title "[_ tasks.Delete_task_pretty]"
    set context [list $title]
    set task2_pretty [ad_decode $num_entries 1 "[_ tasks.this_task]" "[_ tasks.these_tasks]"]
    set context [list $title]
    set question "[_ tasks.lt_Are_you_sure_you_want_1]"
    set yes_url "delete?[export_vars { task_id:multiple { confirm_p 1 } return_url}]"                                                    
    set no_url "${return_url}"
    return
}


set task_titles [list]
foreach task_id $task_id {
    lappend task_titles [db_string get_task_title {
	select t.title
	from t_tasks
	where t.task_id = :task_id
    }]
    db_dml mark_delete {
	update t_tasks
	set status_id = null
	where task_id = :task_id
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
    util_user_message -html -message "[_ tasks.lt_The_tasks_task_list_w]"
} else {
    set task_title [lindex $task_titles 0]
    util_user_message -html -message "[_ tasks.lt_The_task_lindex_task_]"
}

ad_returnredirect $return_url
ad_script_abort
