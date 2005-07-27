<if @assignee_id@ not nil>
<master src="/packages/contacts/custom/mbbs-contact-master">
<property name="party_id">@assignee_id@</property>
</if>
<else>
<master src="/packages/contacts/custom/mbbs-contacts-master" />
</else>
<if @assignee_id@ not nil>
<p><a href="@cancel_url@" class="button">#tasks.Cancel#</a></p>
</if>
<listtemplate name="processes"></listtemplate>



