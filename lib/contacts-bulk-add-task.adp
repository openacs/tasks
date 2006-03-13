<master src="/packages/contacts/lib/contacts-master" />
<property name="context">@context@</property>
<property name="title">@title@</property>
<property name="focus">add_edit.one_line</property>

<include src="/packages/tasks/lib/task-form"
	 object_id=@party_id;noquote@
         return_url=@return_url;noquote@ 
         export_vars_list=@party_id@ />
