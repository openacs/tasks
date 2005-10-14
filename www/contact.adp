<master src="/packages/contacts/custom/mbbs-contact-master">
<property name="party_id">@party_id@</property>

<table widht="50%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks"
		 party_id=@party_id@
		 orderby="@orderby@"
		 page="@page@"
		 page_size="@page_size@"
                 search_id=""
                 row_list="@row_list@"
                 query=""/>
    </td>
</tr>
</table>
