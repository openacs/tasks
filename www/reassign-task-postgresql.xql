<?xml varsion="1.0"?>
<queryset>

<fullquery name="get_all_users">
    <querytext>
	select 
		case 
		    when 
			email is not null 
		    then
			 title||' ('||email||')' 
		    else 
			 title 
		end, 
		user_id 
	from 
		cc_users 
	where 
		user_id <> :user_id 
	order by 
		title asc	
    </querytext>
</fullquery>

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