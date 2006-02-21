<master src="@portlet_layout@">
<property name="portlet_title">#tasks.Tasks#</property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	<include src="/packages/tasks/lib/tasks"
		party_id=@party_id@
 		query="@query@"
 		search_id="@search_id@"
		tasks_previous="@tasks_previous@"
		tasks_future="@tasks_future@"
		tasks_orderby="@tasks_orderby@"
		page="@page@"
		page_size="@page_size@"
		page_flush_p="@page_flush_p@" />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>


