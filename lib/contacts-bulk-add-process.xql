<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="process_exists">
    <querytext>
        select 1
          from t_processes p,
               acs_objects o
         where p.process_id = o.object_id
           and p.workflow_id is not null
           and o.package_id = :package_id
           and p.process_id = :process_id
    </querytext>
</fullquery>

<fullquery name="get_process_title">
    <querytext>
        select p.title
          from t_processes p,
               acs_objects o
         where p.process_id = o.object_id
           and p.workflow_id is not null
           and o.package_id = :package_id
           and p.process_id = :process_id
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

</queryset>
