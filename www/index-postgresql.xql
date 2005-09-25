<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="tasks_select">
    <querytext>
        select t.task_id, t.title, t.party_id, t.priority, s.title as status,
               tasks__relative_date(t.due_date) as due_date,
               CASE WHEN t.due_date < now() THEN 't'::boolean ELSE 'f'::boolean END as overdue_p,
               to_char(t.due_date,'YYYY-MM-DD HH24:MI') as due_date,
               contact__name(t.party_id, :name_order) as contact_name,
               p.title as process_title, p.process_id
        from t_task_status s, acs_objects ot, t_tasks t
        left outer join t_process_instances pi
        on (pi.process_instance_id = t.process_instance_id)
        left outer join t_processes p
        on (p.process_id = pi.process_id)
        where s.status_id = t.status_id
        and ot.object_id = t.task_id
        and ot.package_id = :package_id
        and t.start_date > now()
        and t.due_date < ( now() + '$tasks_interval days'::interval )
        [template::list::page_where_clause -and -name tasks -key t.task_id]
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="tasks_pagination">
    <querytext>
        select t.task_id
        from t_task_status s, acs_objects ot, t_tasks t
        left outer join t_process_instances pi
        on (pi.process_instance_id = t.process_instance_id)
        left outer join t_processes p
        on (p.process_id = pi.process_id)
        where s.status_id = t.status_id
        and ot.object_id = t.task_id
        and ot.package_id = :package_id
        and t.start_date > now()
        and t.due_date < ( now() + '$tasks_interval days'::interval )
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
</fullquery>

<fullquery name="tasks_count">
    <querytext>
        select count(*)
        from t_task_status s, acs_objects ot, t_tasks t
        left outer join t_process_instances pi
        on (pi.process_instance_id = t.process_instance_id)
        left outer join t_processes p
        on (p.process_id = pi.process_id)
        where s.status_id = t.status_id
        and ot.object_id = t.task_id
        and ot.package_id = :package_id
        and t.start_date > now()
        and t.due_date < ( now() + '$tasks_interval days'::interval )
    </querytext>
</fullquery>

</queryset>
