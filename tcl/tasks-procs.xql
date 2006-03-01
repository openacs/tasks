<?xml version="1.0"?>
<queryset>

   <fullquery name="tasks::belong_to_package.objects_belong_to_package_p">
         <querytext>

            select 1
              from acs_objects
             where object_id in ([template::util::tcl_to_sql_list $objects])
             limit 1

         </querytext>
   </fullquery>

   <fullquery name="tasks::task::title.get_task_title">
         <querytext>

            select title from t_tasks where task_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::task::delete.delete_task">
         <querytext>

	    update t_tasks
               set status_id = null
	     where task_id = :task_id

         </querytext>
   </fullquery>

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

   <fullquery name="tasks::task::edit.get_status_id">
         <querytext>

        select status_id
          from t_tasks
         where task_id = :task_id

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
            due_date = :due_date,
	    assignee_id = :assignee_id
            $completed_clause
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

   <fullquery name="tasks::process::task::edit.update_object">
         <querytext>

	update acs_objects
	set modifying_user = :modifying_user,
	    modifying_ip = :modifying_ip,
            last_modified = now()
	where object_id = :task_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::assign.get_workflow_id">
         <querytext>

	select workflow_id
	  from t_processes
	 where process_id = :process_id

         </querytext>
   </fullquery>


   <fullquery name="tasks::process::assign.get_case">
         <querytext>

        select case_id
          from workflow_cases
         where workflow_id = :workflow_id
           and object_id = :object_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::assign.update_instance_case">
         <querytext>

        update t_process_instances
           set case_id = :case_id
         where instance_id = :instance_id

         </querytext>
   </fullquery>

   <fullquery name="tasks::process::edit.update_process">
         <querytext>

	update t_processes
	set title = :title,
	    description = :description,
	    mime_type = :mime_type,
            assignee_id = :assignee_id
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
