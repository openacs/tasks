<master src="/packages/contacts/lib/contacts-master" />
<p><formtemplate id="search" style="proper-inline"></formtemplate></p>

<br />
<table width="100%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks-portlet"
		 user_id=@user_id@
		 query="@query@"
		 search_id="@search_id@"
		 tasks_interval="@tasks_interval@"
		 tasks_orderby="@tasks_orderby@"
		 page="@page@"
		 page_size="@page_size@"
		 page_flush_p="@page_flush_p@" />
    </td>
</tr>
</table>