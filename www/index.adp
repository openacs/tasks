<master src="/packages/contacts/lib/contacts-master" />
<p><formtemplate id="search" style="proper-inline"></formtemplate></p>

<br />
<table width="50%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks"
		 user_id=@user_id@
		 query="@query@"
		 search_id="@search_id@"
		 tasks_interval="@tasks_interval@"
		 orderby="@orderby@"
		 page="@page@"
		 page_size="@page_size@">
    </td>
</tr>
</table>