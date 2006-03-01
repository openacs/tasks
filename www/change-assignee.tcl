ad_page_contract {
    
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation_date 2005-10-23
} {
    {task_id:multiple,optional ""}
    {process_task_id:multiple,optional ""}
    {party_id ""}
    {return_url ""}
}

tasks::require_belong_to_package -objects $task_id

set required_p 0

if { ![exists_and_not_null task_id] } {
    if { ![exists_and_not_null process_task_id] } {
	set required_p 1
    }
} elseif { ![exists_and_not_null process_task_id] } {
    if { ![exists_and_not_null task_id] } {
	set required_p 1
    }
}

if { $required_p } {
    ad_return_complaint 1 "You need to provided either task_id or process_task_id"
    ad_script_abort
}

set page_title "[_ tasks.Change_Assignee]"
set context [list "$page_title"]

if { ![exists_and_not_null return_url] } {
    set return_url [get_referrer]
}

if { [exists_and_not_null task_id] } {
    set tasks_list [join $task_id ", \#"]
}

if { [exists_and_not_null process_task_id] } {
    set tasks_list [join $process_task_id ", \#"]
}

ad_form -name change_assignee -form {
    {tasks_show:text(inform) 
	{label "[_ tasks.Tasks]:"}
	{value "\#$tasks_list"}
    }
    {task_id:text(hidden) {value $task_id}}
    {process_task_id:text(hidden) {value $process_task_id}}
    {party_id:party_search(party_search) 
	{label "[_ tasks.Search_Assignee]:"} 
	{help_text "[_ tasks.Search_Assignee_help]"}
    }
    {return_url:text(hidden) {value $return_url}}
} -on_submit {
    if { [exists_and_not_null task_id] } {
	foreach task $task_id {
	    db_dml update_tasks { }
	}
    }
    if { [exists_and_not_null process_task_id] } {
	foreach process_task $process_task_id {
	    db_dml update_process_tasks { }
	}
    }
} -after_submit {
    ad_returnredirect $return_url
}
