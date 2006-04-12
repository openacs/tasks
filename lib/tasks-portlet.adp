<master src="@portlet_layout@">
<property name="portlet_title">#tasks.Tasks#</property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	     <include
        	src="/packages/tasks/lib/tasks"
	        object_query=@object_query@
		page_size="50" 
		show_filters_p="1"
                hide_elements=""
                start_date=@start_date@
                end_date=@end_date@
                assignee_query=@assignee_query@ />	
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>


