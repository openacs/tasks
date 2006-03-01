<master src="/packages/contacts/lib/contact-master" />
<property name="party_id">@object_id@</property>

<table width="100%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks"
		 object_id=@object_id@
		 page_size="25"
                 elements="checkbox deleted_p priority title process_title date assignee"
                 page_flush_p="0"
		 show_filters_p="t"
                 package_id=@package_id@ />
    </td>
</tr>
</table>
<%
#		 emp_f="@emp_f@"
#		 tasks_interval="@tasks_interval@"
#                 query=""
%>
