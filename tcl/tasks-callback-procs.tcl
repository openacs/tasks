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
    set project_id "26798"
    set tasks [list]
    db_foreach get_tasks {
        select pt.task_id,
               tasks__completion_date(ci.item_id) as completion_date,
               tasks__completion_user(ci.item_id) as completion_user,
               cr.title,
               cr.description as content
          from cr_items ci,
               pm_tasks_revisions ptr,
               pm_tasks pt left join pm_process_instance ppi on (pt.process_instance = ppi.instance_id ),
               cr_revisions cr,
               acs_objects ao
         where ci.parent_id = :project_id
           and ci.item_id = pt.task_id
           and ci.latest_revision = ptr.task_revision_id
           and ci.live_revision = ptr.task_revision_id
           and ptr.task_revision_id = cr.revision_id
           and cr.revision_id = ao.object_id
           and pt.status = '2'
           and pt.deleted_p = 'f'
           and task_id in ( select task_id from pm_task_assignment where party_id = :party_id and role_id = '1' )
    } {
	if { [exists_and_not_null truncate_len] } {
	    set content_html [ad_html_text_convert -truncate_len $truncate_len -from "text/plain" -to "text/html" $content]
	} else {
	    set content_html [ad_html_text_convert -from "text/plain" -to "text/html" $content]
	}
	::template::multirow append $multirow $completion_date $task_id $completion_user [list $title $content_html] "/packages/tasks/lib/task-chunk"
    }
}


ad_proc -public -callback contacts::bulk_actions -impl tasks {
    {-multirow:required}
} {
    Add task history to this party. Return as list
} {
    ::template::multirow append $multirow "Add Task" "/tasks/task" "Add a task to the selected contacts"
}


ad_proc -public tasks::workflow::impl::action_side_effect::do {
    case_id
    object_id
    action_id
    entry_id
} {
    create new tasks linked to this action
} {
    db_1row process_id {
	select process_instance_id, process_id, party_id
	from t_process_instances
	where case_id = :case_id
    }

    set tasks [db_list_of_lists process_tasks {
	select task_id, title, description,
               mime_type, comment, status_id, priority,
	       to_char((now()+ (start::varchar || ' days')::interval), 'YYYY-MM-DD') as start_date,
	       to_char((now()+ (due::varchar || ' days')::interval), 'YYYY-MM-DD') as due_date
	from t_process_tasks
	where open_action_id = :action_id
    }]

    foreach task $tasks {
	util_unlist $task process_task_id title description mime_type comment status_id priority start_date due_date

	set new_task_id [tasks::task::new \
			    -process_instance_id $process_instance_id \
			    -process_task_id $process_task_id \
			    -party_id $party_id \
			    -object_id $object_id \
			    -title $title \
			    -description $description \
			    -mime_type $mime_type \
			    -comment $comment \
			    -status_id $status_id \
			    -priority $priority \
			    -start_date $start_date \
			    -due_date $due_date]
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
