# 

ad_page_contract {
    
    Delete a process
    
    @author Jade Rubick (jader@bread.com)
    @creation-date 2004-06-25
    @arch-tag: e4153029-2cda-462d-b429-8f2b24999580
    @cvs-id $Id$
} {
    process_id:integer
    {confirm_p:boolean 0}
    {return_url "processes"}
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]


if {[string is false $confirm_p]} {

    db_1row get_name "select one_line, description from pm_process where process_id = :process_id"

    set title "Delete process: $one_line"
    set context [list "Delete: $one_line"]

    set yes_url "process-delete?[export_vars {process_id {confirm_p 1} return_url}]"
    set no_url $return_url

    return
}


permission::require_permission -object_id $package_id -privilege delete
db_transaction {
    db_dml delete_extra_stuff {
	delete from tasks_pm_process_task where process_task_id in ( select process_task_id from pm_process_task where process_id = :process_id )
    }
    pm::process::delete -process_id $process_id
}
ad_returnredirect -message "Process deleted" $return_url
