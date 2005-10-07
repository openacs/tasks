<?xml version="1.0"?>
<queryset>

   <fullquery name="tasks::edit.update_task">
         <querytext>

	update tasks
	set title = :title,
	    description = :description,
	    mime_type = :mime_type,
	    comment = :comment,
	    due_date = :due_date,
	    priority = :priority,
	    status = :status
	where task_id = :task_id

         </querytext>
   </fullquery>

</queryset>
