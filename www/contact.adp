<master src="/packages/contacts/custom/mbbs-contact-master">
<property name="party_id">@party_id@</property>

<table widht="50%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks-portlet"
		 party_id=@party_id@
		 orderby="@orderby@"
		 page="@page@"
		 page_size="@page_size@"
		 page_flush_p="f"/>
    </td>
</tr>
</table>
