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

ad_proc -public tasks::require_belong_to_package {
    {-objects ""}
    {-package_id ""}
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    if { ![tasks::belong_to_package -objects $objects -package_id $package_id] } {
	ad_return_complain 1 [_ tasks.Your_submission_is_not_valid]
    }

}

ad_proc -public tasks::belong_to_package {
    {-objects ""}
    {-package_id ""}
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    if { [llength $objects] == 0 } {
	return 1
    } else {
	return [db_0or1row objects_belong_to_package_p {}]
    }
}

ad_proc -public tasks::get_submitted_as_list {
} {
    set form_variables [list]
    set form [ns_getform]
    if { $form eq "" } {
	set form_size 0
    } else {
	set form_size [ns_set size $form]
    }
    for { set form_counter_i 0 } { $form_counter_i < $form_size } { incr form_counter_i } {
	set key [ns_set key $form $form_counter_i]
	set value [ns_set value $form $form_counter_i]
	if { $value ne "" } {
	    lappend form_variables $key $value
	}
    }
    return $form_variables
}


ad_proc -public tasks::relative_date {
    {-date:required}
} {
    if { [regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}} $date match] } {

	# get year, month, day
	set date_list [dt_ansi_to_list [lindex $date 0]]
        set date_julian [dt_ansi_to_julian [lindex $date_list 0] [lindex $date_list 1] [lindex $date_list 2]]

        set today_date [dt_sysdate]
        set today_list [dt_ansi_to_list $today_date]
        set today_julian [dt_ansi_to_julian [lindex $today_list 0] [lindex $today_list 1] [lindex $today_list 2]]

	set days [expr $date_julian - $today_julian]

	if { $days == 0 } {
	    set date [_ acs-datetime.Today]
	} elseif { $days == -1 } {
	    set date [_ tasks.Yesterday]
	} elseif { $days == 1 } {
	    set date [_ tasks.Tomorrow]
	} elseif { 1 < $days && $days <= 5 } {
	    set weekday [lc_time_fmt $date "%f"]
	    set todays_weekday [lc_time_fmt $today_date "%f"]
	    if { $todays_weekday <= 5 && $weekday <= 5 } {
		set date [lindex [_ acs-datetime.days_of_week] $weekday]
	    } else {
		set date [lc_time_fmt $date [_ tasks.localization-d_near_fmt]]
	    }
	} elseif { ( -30 < $days && $days < -1 ) || ( 5 < $days && $days <= 180 ) } {
	    set date [lc_time_fmt $date [_ tasks.localization-d_near_fmt]]
	} else {
	    set date [lc_time_fmt $date [_ tasks.localization-d_far_fmt]]
	}

    }
    return $date
}

ad_proc -public tasks::task::new {
    {-task_id ""}
    {-process_instance_id ""}
    {-process_task_id ""}
    -object_id:required
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
        set package_id [ad_conn package_id]
    }
    set extra_vars [ns_set create]

    if { [empty_string_p $context_id] } {
	set context_id $package_id
    }

    if { [empty_string_p $assignee_id] } {
	set assignee_id [ad_conn user_id]
    }

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {task_id process_instance_id process_task_id object_id title description mime_type comment status_id priority start_date due_date package_id context_id assignee_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_task]

    return $task_id
}

ad_proc -public tasks::task::title {
    -task_id
} {
    return [db_string get_task_title {} -default {}]
}

ad_proc -public tasks::task::delete {
    -task_id
} {
    db_dml delete_task {}
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

    set previous_status_id [db_string get_status_id {}]

    if { $status_id == $previous_status_id } {
	# there is no need to updated the completed_date
	set completed_clause ""
    } elseif { $status_id == "2" } {
	# the edit is completing the task for the first time
	set completed_clause ", completed_date = now()"
    } else {
	# the edit is no longer completed
	set completed_clause ", completed_date = NULL"
    }

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

ad_proc -public tasks::task::modify_interval {
    -task_id:required
    -method:required
    {-days "7"}
} {
    increase or decrease a task interval
} {
    if { $method == "increase" } {
	set operand "+"
    } elseif { $method == "decrease" } {
	set operand "-"
    } else {
	error "an invalid method was supplied to tasks::task::modify_interval, you specified ${method}, but it must be 'increase' or 'decrease'"
    }


    db_1row get_task_info "
    select t.title as task, t.description, t.mime_type, t.priority,
           to_char((t.due_date $operand '$days days'::interval),'YYYY-MM-DD') as due_date,
           t.status_id as status, t.comment, t.assignee_id
      from t_tasks t
     where t.task_id = :task_id
    "
    
    set task_id [tasks::task::edit \
		     -task_id ${task_id} \
		     -title ${task} \
		     -description ${description} \
		     -mime_type $mime_type \
		     -comment ${comment} \
		     -due_date ${due_date} \
		     -status_id ${status} \
		     -assignee_id ${assignee_id} \
		     -priority ${priority}]

}


ad_proc -public tasks::process::task::new {
    {-task_id ""}
    -process_id:required
    -open_action_id:required
    -closing_action_id:required
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

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {task_id process_id open_action_id closing_action_id object_id title description mime_type comment status_id priority start due package_id context_id assignee_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_process_task]

    return $task_id
}

ad_proc -public tasks::process::task::edit {
    -task_id:required
    -open_action_id:required
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


ad_proc -public tasks::process::assign {
    -process_id:required
    -object_id:required
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }
    ns_log notice "the process_id is $process_id and the object_id is $object_id"

    set workflow_id [db_string get_workflow_id {}]

    db_transaction {
	set case_id [db_nextval acs_object_id_seq]

	set instance_id [tasks::process::instance::new \
			     -process_id $process_id \
			     -case_id $case_id \
			     -package_id $package_id \
			     -object_id $object_id]
	
	workflow::case::new -no_notification \
	    -workflow_id $workflow_id \
	    -case_id $case_id \
	    -object_id $instance_id
	
    }

    # ideally in the future we could specify the case_id
    # that workflow::case::new would use, and thus we
    # could create an object_id before creating
    # the process instance but for now we
    # need this hack

#    set case_id [db_string get_case {} -default {}]

#    db_dml update_instance_case {}

    return $instance_id
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
    {-assignee_id ""}
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
    -object_id:required
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }
    set extra_vars [ns_set create]
    set context_id $package_id

    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {process_instance_id process_id case_id object_id package_id context_id}

    set task_id [package_instantiate_object -extra_vars $extra_vars tasks_process_instance]

    return $task_id
}
