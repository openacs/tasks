<master src="/packages/contacts/lib/contacts-master" />
<p><formtemplate id="search" style="proper-inline"></formtemplate></p>

<br />
<table width="100%">
<tr>
    <td>
	<include src="/packages/tasks/lib/tasks-portlet"
                 object_query=@object_query;noquote@ 
                 start_date=@start_date@
                 end_date=@end_date@ />

    </td>
</tr>
</table>
