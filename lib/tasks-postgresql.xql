<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="status_options">
    <querytext>
        select title, 
               status_id
          from t_task_status
         order by status_id
    </querytext>
</fullquery>

<fullquery name="task_available_for_action">
    <querytext>
        select '1'
          from t_task_status s,
               acs_objects ao,
               t_tasks t
         where s.status_id = t.status_id
           and ao.object_id = t.task_id
           and t.task_id = :task_action_id
        $limitations_clause
    </querytext>
</fullquery>

<fullquery name="processes">
    <querytext>
        select p.process_id,
               p.title,
               o.creation_user,
               person__name(o.creation_user) as creator_name,
               p.description
          from t_processes p,
               acs_objects o
         where p.process_id = o.object_id
           and p.workflow_id is not null
           and o.package_id = :package_id
         order by lower(p.title)
    </querytext>
</fullquery>

<fullquery name="tasks">
    <querytext>
	select t.task_id, 
               t.title,
               t.description, 
               t.mime_type,
               t.priority,
               p.title as process_title, 
               p.process_id,
               t.due_date,
               t.completed_date,
               t.status_id, 
               t.process_instance_id,
               t.assignee_id,
               CASE WHEN t.due_date::date <= now()::date THEN 't' ELSE 'f' END as due_date_passed_p,
               s.title as status, 
               t.object_id,
               acs_object__name(t.object_id) as object_name
     	  from t_task_status s, 
	       acs_objects ao, 
	       t_tasks t
               left outer join t_process_instances pi on (pi.process_instance_id = t.process_instance_id)
      	       left outer join t_processes p on (p.process_id = pi.process_id)
      	 where s.status_id = t.status_id
           and ao.object_id = t.task_id
    	[template::list::page_where_clause -and -name tasks -key t.task_id]
     	[template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="tasks_pagination">
    <querytext>
        select t.task_id
          from t_task_status s,
               acs_objects ao,
               t_tasks t
               left outer join t_process_instances pi on (pi.process_instance_id = t.process_instance_id)
      	       left outer join t_processes p on (p.process_id = pi.process_id)
         where s.status_id = t.status_id
           and ao.object_id = t.task_id
        $limitations_clause
        [list::filter_where_clauses -and -name tasks]
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

</queryset>
