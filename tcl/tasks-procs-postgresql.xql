<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="tasks::new.create_task">
        <querytext>

	select tasks__new (
			   :party_id,
			   :object_id,
			   :process_id,
			   :title,
			   :description,
			   :mime_type,
			   :comment,
			   :due_date,
			   :priority,
			   :status,
			   now(),
			   :user_id,
			   :ip_addr,
			   :package_id
			   )

        </querytext>
    </fullquery>

    <fullquery name="tasks::edit.update_object">
        <querytext>

	update acs_objects
	set title = :title,
	    modifying_user = :user_id,
	    modifying_ip = :ip_addr,
	    last_modified = now()
	where object_id = :task_id

        </querytext>
    </fullquery>

</queryset>
