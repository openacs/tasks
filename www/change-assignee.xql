<?xml version="1.0"?>
<queryset>

<fullquery name="update_tasks">
    <querytext>
	update t_tasks 
	set assignee_id = :party_id 
	where task_id = :task
    </querytext>
</fullquery>

<fullquery name="update_process_tasks">
    <querytext>
	update t_process_tasks 
	set assignee_id = :party_id 
	where task_id = :process_task
    </querytext>
</fullquery>

</queryset>