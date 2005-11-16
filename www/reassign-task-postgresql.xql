<?xml varsion="1.0"?>
<queryset>

<fullquery name="update_t_tasks">
    <querytext>
	update 
		t_tasks 
	set 
		party_id = :reassign_party 
	where 
		task_id = :task
    </querytext>
</fullquery>

</queryset>