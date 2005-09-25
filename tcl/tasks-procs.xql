<?xml version="1.0"?>
<queryset>

   <fullquery name="tasks::task::complete.set_status_done">
         <querytext>

	    update t_tasks
	    set status_id = 2,
                completed_date = now()
	    where task_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::task::complete.closing_action">
         <querytext>

	    select pt.closing_action_id, pi.case_id
	    from t_process_tasks pt, t_tasks t, t_process_instances pi
	    where pt.task_id = t.process_task_id
	    and pi.process_instance_id = t.process_instance_id
	    and t.task_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::task::edit.update_task">
         <querytext>

	update t_tasks
	set title = :title,
	    description = :description,
            mime_type = :mime_type,
            comment = :comment,
            status_id = :status_id,
            priority = :priority,
            due_date = :due_date
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
            due = :due
	where task_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::task::edit.update_object">
         <querytext>

	update acs_objects
	set modifying_user = :modifying_user,
	    modifying_ip = :modifying_ip,
            last_modified = now()
	where object_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::edit.update_process">
         <querytext>

	update t_processes
	set title = :title,
	    description = :description,
	    mime_type = :mime_type
	where process_id = :process_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::edit.update_object">
         <querytext>

	update acs_objects
	set modifying_user = :modifying_user,
	    modifying_ip = :modifying_ip,
            last_modified = now()
	where object_id = :process_id

         </querytext>
   </fullquery>

</queryset>
