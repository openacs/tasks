<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="get_tasks">
    <querytext>
	select 
		t.task_id, 
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

<fullquery name="tasks">
    <querytext>
        SELECT
        ts.task_id as task_item_id,
        ts.task_number,
        t.task_revision_id,
        t.title,
        t.description,
        t.parent_id as project_item_id,
        proj_rev.logger_project,
        proj_rev.title as project_name,
        to_char(t.earliest_start,'J') as earliest_start_j,
        to_char(current_timestamp,'J') as today_j,
        to_char(t.latest_start,'J') as latest_start_j,
        to_char(t.latest_start,'YYYY-MM-DD HH24:MI') as latest_start,
        to_char(t.latest_finish,'YYYY-MM-DD HH24:MI') as latest_finish,
        t.percent_complete,
        t.estimated_hours_work,
        t.estimated_hours_work_min,
        t.estimated_hours_work_max,
        case when t.actual_hours_worked is null then 0
                else t.actual_hours_worked end as actual_hours_worked,
        to_char(t.earliest_start,'YYYY-MM-DD HH24:MI') as earliest_start,
        to_char(t.earliest_finish,'YYYY-MM-DD HH24:MI') as earliest_finish,
        to_char(t.latest_start,'YYYY-MM-DD HH24:MI') as latest_start,
        to_char(t.latest_finish,'YYYY-MM-DD HH24:MI') as latest_finish,
        p.first_names || ' ' || p.last_name as full_name,
        r.one_line as role
        FROM
        pm_tasks_active ts, 
        cr_items i,
        pm_tasks_revisionsx t 
          LEFT JOIN pm_task_assignment ta
          ON t.item_id = ta.task_id
            LEFT JOIN persons p 
            ON ta.party_id = p.person_id
            LEFT JOIN pm_roles r
            ON ta.role_id = r.role_id,
        cr_items proj,
        pm_projectsx proj_rev
        WHERE
        ts.task_id  = t.item_id and
        i.item_id   = t.item_id and
        t.task_revision_id = i.live_revision and 
        t.parent_id = proj.item_id and
        proj.live_revision = proj_rev.revision_id
        [template::list::filter_where_clauses -and -name tasks]
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

</queryset>
