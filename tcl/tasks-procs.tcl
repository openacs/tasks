ad_library {

    Tasks Library

    @creation-date 2003-12-18
    @author Matthew Geddert <openacs@geddert.com>
    @cvs-id $Id$

}

namespace eval tasks {}
namespace eval tasks::task {}
namespace eval tasks::process {}
namespace eval tasks::process::task {}
namespace eval tasks::process::instance {}


ad_proc -public tasks::new {
    -party_id:required
    {-object_id ""}
    {-process_id ""}
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    -due_date:required
    {-priority 0}
    {-status "o"}
    {-user_id ""}
    {-ip_addr ""}
    {-package_id ""}
} {
    insert new task
} {
    if {[empty_string_p $package_id]} {
	set package_id [ad_conn package_id]
    }
    if {[empty_string_p $user_id]} {
	set user_id [ad_conn user_id]
    }
    if {[empty_string_p $ip_addr]} {
	set ip_addr [ad_conn peeraddr]
    }

    set task_id [db_exec_plsql create_task {}]

    return $task_id
}

ad_proc -public tasks::edit {
    -task_id:required
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    -due_date:required
    {-priority 0}
    {-status "o"}
    {-user_id ""}
    {-ip_addr ""}
} {
    update task
} {
    if {[empty_string_p $user_id]} {
	set user_id [ad_conn user_id]
    }
    if {[empty_string_p $ip_addr]} {
	set ip_addr [ad_conn peeraddr]
    }

    db_dml update_task {}
    db_dml update_object {}
}


ad_proc -public tasks::project_id {
    {-package_id ""}
} {
    Returns this tasks instance project_id
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    set project_id [db_string get_project_id {
        select pm_projectsx.item_id
          from pm_projectsx,
               cr_folders cf
         where pm_projectsx.parent_id = cf.folder_id
           and cf.package_id = :package_id
    } -default {}]
    if { [string is false [exists_and_not_null project_id]] } {
	tasks::initialize -package_id $package_id
	set project_id [tasks::project_id -package_id $package_id]
    }
    return $project_id
}

ad_proc -public tasks::initialize {
    {-package_id ""}
} {
    Returns this tasks instance project_id
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    if { [string is false [db_0or1row project_exists_p { select 1 from cr_folders where package_id = :package_id and label = 'Projects' }]] } {
	pm::project::new -project_name "[_ tasks.Tasks_Instance]" \
	    -status_id "1" \
	    -organization_id "" \
	    -creation_user [ad_conn user_id] \
	    -creation_ip [ad_conn peeraddr] \
	    -ongoing_p "t" \
	    -package_id $package_id
    }
}


ad_proc -public tasks::task::new {
    {-task_id ""}
    {-process_instance_id ""}
    {-process_task_id ""}
    {-party_id ""}
    {-object_id ""}
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    {-status_id 1}
    {-priority 0}
    {-start_date ""}
    {-due_date ""}
    {-package_id ""}
    {-context_id ""}
    {-assignee_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [apm_package_id_from_key "tasks"]
    }
    set extra_vars [ns_set create]

    if { [empty_string_p $context_id] } {
	set context_id $package_id
    }

    if { [empty_string_p $assignee_id] } {
	set assignee_id [ad_conn user_id]
    }

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {task_id process_instance_id process_task_id party_id object_id title description mime_type comment status_id priority start_date due_date package_id context_id assignee_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_task]

    return $task_id
}

ad_proc -public tasks::task::edit {
    -task_id:required
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    {-status_id 1}
    {-priority 0}
    {-due_date ""}
    {-assignee_id ""}
} {
    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_dml update_task {}
    db_dml update_object {}
}

ad_proc -public tasks::task::complete {
    -task_id:required
} {
    db_transaction {
	db_dml set_status_done {}

	if {[db_0or1row closing_action {}]} {
	    workflow::case::action::execute -case_id $case_id -action_id $closing_action_id -no_perm_check -no_notification
	}
    }
}


ad_proc -public tasks::process::task::new {
    {-task_id ""}
    -process_id:required
    -open_action_id:required
    -closing_action_id:required
    {-party_id ""}
    {-object_id ""}
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    {-status_id 1}
    {-priority 0}
    {-start 0}
    {-due 0}
    {-package_id ""}
    {-assignee_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    if { [empty_string_p $assignee_id] } {
	set assignee_id [ad_conn user_id]
    }

    set extra_vars [ns_set create]
    set context_id $package_id

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {task_id process_id open_action_id closing_action_id party_id object_id title description mime_type comment status_id priority start due package_id context_id assignee_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_process_task]

    return $task_id
}

ad_proc -public tasks::process::task::edit {
    -task_id:required
    -open_action_id:required
    {-party_id ""}
    {-object_id ""}
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-comment ""}
    {-status_id 1}
    {-priority 0}
    {-start 0}
    {-due 0}
    {-assignee_id ""}
} {
    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_dml update_process_task {}
    db_dml update_object {}
}


ad_proc -public tasks::process::new {
    {-process_id ""}
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
    {-workflow_id ""}
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }
    set extra_vars [ns_set create]
    set context_id $package_id

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {process_id title description mime_type workflow_id package_id context_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_process]

    return $task_id
}

ad_proc -public tasks::process::edit {
    -process_id:required
    -title:required
    {-description ""}
    {-mime_type "text/plain"}
} {
    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_dml update_process {}
    db_dml update_object {}
}


ad_proc -public tasks::process::instance::new {
    {-process_instance_id ""}
    -process_id:required
    -case_id:required
    {-party_id ""}
    {-object_id ""}
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }
    set extra_vars [ns_set create]
    set context_id $package_id

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {process_instance_id process_id case_id party_id object_id package_id context_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_process_instance]

    return $task_id
}
