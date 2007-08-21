# packages/tasks/tcl/tasks-callback-procs.tcl

ad_library {
    
    Callback procs for Tasks
    
    @author Matthew Geddert (openacs@geddert.com)
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-06-15
    @arch-tag: 200d82ba-f8e7-4f19-9740-39117474766f
    @cvs-id $Id$
}

namespace eval tasks::workflow {}
namespace eval tasks::workflow::impl {}
namespace eval tasks::workflow::impl::action_side_effect {}


ad_proc -public -callback contact::history -impl tasks {
    {-party_id:required}
    {-multirow:required}
    {-trunacte_len ""}
} {
    Add task history to this party. Return as list
} {
    set tasks [list]
    db_foreach get_tasks {
        select t.task_id,
               t.completed_date as completion_date,
               ao.modifying_user as completion_user,
               t.title,
               t.description as content
          from t_tasks t,
               acs_objects ao
         where t.task_id = ao.object_id
           and t.object_id = :party_id
	   and t.status_id = '2'
    } {
	if { [exists_and_not_null truncate_len] } {
	    set content_html [ad_html_text_convert -truncate_len $truncate_len -from "text/textile" -to "text/html" $content]
	} else {
	    set content_html [ad_html_text_convert -from "text/textile" -to "text/html" $content]
	}
	::template::multirow append $multirow $completion_date $task_id $completion_user [list $title $content_html] "/packages/tasks/lib/task-chunk"
    }
}

ad_proc -public -callback contacts::bulk_actions -impl tasks {
    {-multirow:required}
} {
    Add task history to this party. Return as list
} {
    ::template::multirow append $multirow "[_ tasks.Add_Task]" "[ad_conn package_url]bulk-add-task" "[_ tasks.Add_a_task_to_the]"
    ::template::multirow append $multirow "[_ tasks.Add_Process]" "[ad_conn package_url]bulk-add-process" "[_ tasks.Add_a_process_to_the]"
}


ad_proc -public tasks::workflow::impl::action_side_effect::do {
    case_id
    object_id
    action_id
    entry_id
} {
    create new tasks linked to this action
} {
    ns_log Debug "\#\#\# entering tasks-action-callback: $case_id, $object_id, $action_id"

    db_1row process_id {
	select tp.process_instance_id,
               tp.process_id,
               tp.object_id,
               o.package_id
          from t_process_instances tp,
               acs_objects o
	 where tp.process_instance_id = o.object_id
           and tp.case_id = :case_id
    }

    set tasks [db_list_of_lists process_tasks {
	select task_id, title, description,
               mime_type, comment, status_id, priority,
	       to_char((now()+ (start::varchar || ' days')::interval), 'YYYY-MM-DD') as start_date,
	       to_char((now()+ (due::varchar || ' days')::interval), 'YYYY-MM-DD') as due_date
               from t_process_tasks
         where open_action_id = :action_id
           and status_id is not null
    }]

    foreach task $tasks {
	util_unlist $task process_task_id title description mime_type comment status_id priority start_date due_date

	set new_task_id [tasks::task::new \
			    -process_instance_id $process_instance_id \
			    -process_task_id $process_task_id \
			    -object_id $object_id \
			    -title $title \
			    -description $description \
			    -mime_type $mime_type \
			    -comment $comment \
			    -status_id $status_id \
			    -priority $priority \
			    -start_date $start_date \
			    -due_date $due_date \
			    -package_id $package_id]
    }
}

ad_proc -public tasks::workflow::impl::action_side_effect::object_type {} {
    Get the object type for which this implementation is valid.
} {
    return "acs_object"
}

ad_proc -public tasks::workflow::impl::action_side_effect::pretty_name {} {
    Get the pretty name of this implementation.
} {
    return "tasks"
}


ad_proc -public -callback contacts::redirect -impl tasks {
    {-party_id ""}
    {-action ""}
} {
    redirect the contact to the correct tasks stuff
} {

    if { [exists_and_not_null party_id] } {

	switch $action {
	    tasks { set file "/packages/tasks/www/contact" }
	    tasks-mark-completed { set file "/packages/tasks/www/mark-completed" }
            tasks-change-assignee { set file "/packages/tasks/www/change-assignee" }
	    tasks-delete { set file "/packages/tasks/www/delete" }
	}

	if { [exists_and_not_null file] } {
	    if { [ns_queryget object_id] eq "" } {
		rp_form_put object_id $party_id
	    }
	    rp_internal_redirect ${file}
	}

    } 
    if  { [regexp "^[ad_conn package_url](.*)$" [ad_conn url] match url_request] } {
	ns_log Debug "tasks implementation of contact::redirecturl_request $url_request"
	switch $url_request {
	    processes { set file "/packages/tasks/www/processes" }
	    process { set file "/packages/tasks/www/process" }
	    process-add-edit { set file "/packages/tasks/www/process-add-edit" }
	    process-delete { set file "/packages/tasks/www/process-delete" }
	    process-task { set file "/packages/tasks/www/process-task" }
	    process-task-delete { set file "/packages/tasks/www/process-task-delete" }
            bulk-add-process { set file "/packages/tasks/lib/contacts-bulk-add-process" }
            bulk-add-task { set file "/packages/tasks/lib/contacts-bulk-add-task" }
            tasks-mail-merge { set file "/packages/tasks/lib/contacts-mail-merge" }
            tasks { set file "/packages/tasks/www/index" }
	    tasks-change-assignee { set file "/packages/tasks/www/change-assignee" }
	    tasks-delete { set file "/packages/tasks/www/delete" }
	}
	if { [exists_and_not_null file] } {
	    rp_internal_redirect $file
	}
    }

}


ad_proc -public -callback subsite::url -impl tasks_task {
    {-package_id:required}
    {-object_id:required}
    {-type ""}
} {
    return the page_url for an object of type tasks_task
} {
#
# I NEED TO FIX THIS, THIS COMES FROM PROJECT MANAGER
#
    if { [apm_package_key_from_id $package_id] eq "contacts" } {
	set party_id [db_string get_it { select party_id from t_tasks where task_id = :object_id } -default {}]
	if { [exists_and_not_null party_id] } {
	    if {$type=="edit"} {
		return "[contact::url -party_id $party_id -package_id $package_id]task/$object_id"
	    } else {
		return "[contact::url -party_id $party_id -package_id $package_id]task/$object_id"
	    }
	}
    } else {

    }



}
