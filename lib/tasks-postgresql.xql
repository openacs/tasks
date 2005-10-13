<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="own_tasks">
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
      	where s.status_id = t.status_id
        and t.status_id <> 2
      	and ao.object_id = t.task_id
        and ao.package_id = :package_id
      	and t.start_date < now()
        and t.due_date < ( now() + '$tasks_interval days'::interval )
        and t.party_id in ( select parties.party_id
                            from parties
                            left join cr_items on (parties.party_id = cr_items.item_id)
                            left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id),
                                 group_distinct_member_map
                            where parties.party_id = group_distinct_member_map.member_id
                            and group_distinct_member_map.group_id = :group_id
                            [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "revision_id"] )
    	[template::list::page_where_clause -and -name tasks -key t.task_id]
	[template::list::filter_where_clauses -and -name tasks]
     	[template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="own_tasks_pagination">
    <querytext>
        select t.task_id
        from t_task_status s, acs_objects ao, t_tasks t
        where s.status_id = t.status_id
        and t.status_id <> 2
        and ao.object_id = t.task_id
        and ao.package_id = :package_id
        and t.start_date < now()
        and t.due_date < ( now() + '$tasks_interval days'::interval )
        and t.party_id in ( select parties.party_id
                            from parties
                            left join cr_items on (parties.party_id = cr_items.item_id)
                            left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id),
                                 group_distinct_member_map
                            where parties.party_id = group_distinct_member_map.member_id
                            and group_distinct_member_map.group_id = :group_id
                            [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "revision_id"] )
	[template::list::filter_where_clauses -and -name tasks]
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="contact_tasks">
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
      	where s.status_id = t.status_id
        and t.status_id <> 2
      	and ao.object_id = t.task_id
        and ao.package_id = :package_id
      	and t.start_date < now()
    	[template::list::page_where_clause -and -name tasks -key t.task_id]
	[template::list::filter_where_clauses -and -name tasks]
     	[template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="contact_tasks_pagination">
    <querytext>
        select t.task_id
        from t_task_status s, acs_objects ao, t_tasks t
        where s.status_id = t.status_id
        and t.status_id <> 2
        and ao.object_id = t.task_id
        and ao.package_id = :package_id
        and t.start_date < now()
	[template::list::filter_where_clauses -and -name tasks]
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

</queryset>
