ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {task_id:integer,multiple,notnull}
    {return_url:notnull}
}

tasks::require_belong_to_package -objects $task_id

set task_titles [list]
foreach task_id $task_id {
    lappend task_titles [tasks::task::title -task_id $task_id]
    tasks::task::delete -task_id $task_id
}

if { [llength $task_titles] > 1 } {
    set task_list ""
    set num 1
    foreach task_title $task_titles {
	if { $num == [llength $task_titles] } {
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
