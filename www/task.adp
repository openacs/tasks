<if @party_count@ gt 1>
<!-- master src="/packages/contacts/custom/mbbs-contacts-master" -->
<master>
</if>
<else>
<!-- master src="/packages/contacts/custom/mbbs-contacts-master" -->
<master>
<property name="party_id">@party_id@</property>
</else>
<formtemplate id="add_edit"></formtemplate>
