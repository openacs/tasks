<?xml version="1.0"?>
<queryset>

   <fullquery name="tasks::edit.update_task">
         <querytext>

	update tasks
	set title = :title,
	    description = :description,
            mime_type = :mime_type,
            comment = :comment,
            status_id = :status_id,
            priority = :priority,
            due_date = :due_date,
	    assignee_id = :assignee_id
	where task_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::task::edit.update_object">
         <querytext>

	update acs_objects
	set modifying_user = :modifying_user,
	    modifying_ip = :modifying_ip,
            last_modified = now()
	where object_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::task::edit.update_process_task">
         <querytext>

	update t_process_tasks
	set open_action_id = :open_action_id,
	    party_id = :party_id,
	    object_id = :object_id,
	    title = :title,
	    description = :description,
            mime_type = :mime_type,
            comment = :comment,
            status_id = :status_id,
            priority = :priority,
	    start = :start,
            due = :due,
	    assignee_id = :assignee_id
	where task_id = :task_id

         </querytext>
   </fullquery>

</queryset>
