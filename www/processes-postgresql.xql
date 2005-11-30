<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.3</version></rdbms>

<fullquery name="process_query">
    <querytext>
        select p.process_id, p.title, o.creation_user,
               person__name(o.creation_user) as creator_name, p.description,
               to_char(o.creation_date, 'YYYY-MM-DD') as creation_date_ansi,
               (select count(*)
                from t_process_instances pi
                where pi.process_id = p.process_id) as instances
        from t_processes p, acs_objects o
        where p.process_id = o.object_id
        and p.workflow_id is not null
        order by lower(p.title)
    </querytext>
</fullquery>

</queryset>
