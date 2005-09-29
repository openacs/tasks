<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="get_tasks">
    <querytext>
	select	t.task_id, 
		t.title, 
		t.description, 
		t.mime_type, 
		t.priority,
           	t.party_id, 
		p.title as process_title, 
		p.process_id,
           	tasks__relative_date(t.due_date) as due_date,
           	tasks__relative_date(t.completed_date) as completed_date,
           	ao.creation_user, 
		t.status_id, 
		t.process_instance_id,
           	contact__name(ao.creation_user) as creation_name,
           	CASE WHEN t.due_date < now() THEN 't' ELSE 'f' END as due_date_passed_p,
           	s.title as status, 
		t.object_id
     	from 
		t_task_status s, 
		acs_objects ao, 
		t_tasks t
      	left outer join t_process_instances pi
      	on (pi.process_instance_id = t.process_instance_id)
      	left outer join t_processes p
      	on (p.process_id = pi.process_id)
      	where 
		s.status_id = t.status_id
      		and ao.object_id = t.task_id
      		and t.start_date < now()
		[template::list::filter_where_clauses -and -name tasks]
     		[template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>


</queryset>
