<master src="/packages/contacts/lib/contact-master" />
<property name="party_id">@party_id@</property>

<table width="100%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks"
		 party_id=@party_id@
		 tasks_orderby="@tasks_orderby@"
		 page="@page@"
		 page_size="@page_size@"
                 search_id=""
                 row_list="@row_list@"
                 page_flush_p="0"
		 show_filters_p="t"
		 emp_f="@emp_f@"
		 tasks_interval="@tasks_interval@"
                 query=""/>
    </td>
</tr>
</table>
