<?xml version="1.0"?>
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

<fullquery name="status_options">
    <querytext>
	select 
		title, 
		status_id
    	from 
		t_task_status
    	order by 
		status_id
    </querytext>
</fullquery>

<fullquery name="get_task_info">
    <querytext>
    	select 
		t.title as task, 
		t.description, 
		t.comment,
                to_char(t.due_date,'YYYY-MM-DD') as due_date,
                t.priority, t.status_id as status, t.object_id
   	from 
		t_tasks t
      	where 
		t.task_id = :task_id
    </querytext>
</fullquery>

<fullquery name="get_it">
    <querytext>
	select 
		creation_user 
	from 
		acs_objects 
	where 
		object_id = :task_id
    </querytext>
</fullquery>
</queryset>