<?xml version="1.0"?>
<queryset>

  <fullquery name="process_query">
    <querytext>
        select title, description, workflow_id
        from t_processes
        where process_id = :process_id
    </querytext>
  </fullquery>

</queryset>
