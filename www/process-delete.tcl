# 

ad_page_contract {
    
    Delete a process
    
    @author Jade Rubick (jader@bread.com)
    @creation-date 2004-06-25
    @arch-tag: e4153029-2cda-462d-b429-8f2b24999580
    @cvs-id $Id$
} {
    process_id:integer
    assignee_id:integer,optional
    {confirm_p:boolean 0}
    {return_url "processes"}
} -properties {
} -validate {
} -errors {
}

tasks::require_belong_to_package -objects $process_id

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege delete

if {[string is false $confirm_p]} {

    db_1row get_name {
	select title, description
	from t_processes
	where process_id = :process_id
    }


    set title "Delete process: $title"
    set context [list "Delete: $title"]
    set process $title

    set yes_url [export_vars -base process-delete {process_id assignee_id {confirm_p 1} return_url}]
    set no_url $return_url

    return
}


db_dml delete_process {
    update t_processes
    set workflow_id = null
    where process_id = :process_id
}

ad_returnredirect -message "Process deleted" $return_url
