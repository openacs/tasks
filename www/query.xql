<?xml version="1.0"?>
<queryset>

<fullquery name="contacts_pagination">
      <querytext>
select parties.party_id
  from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and group_distinct_member_map.group_id = '11428599'
$search_clause
[template::list::orderby_clause -orderby -name "contacts"]
      </querytext>
</fullquery>

<fullquery name="contacts_total_count">
      <querytext>
select count(*)
  from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and group_distinct_member_map.group_id = '11428599'
$search_clause
      </querytext>
</fullquery>

<fullquery name="pretty_roles">
      <querytext>

        select admin_role.pretty_name as admin_role_pretty,
          member_role.pretty_name as member_role_pretty
        from acs_rel_roles admin_role, acs_rel_roles member_role
        where admin_role.role = 'admin'
          and member_role.role = 'member'

      </querytext>
</fullquery>

<fullquery name="get_my_searches">
      <querytext>
    select title, search_id
      from contact_searches
     where owner_id = :owner_id
       and title is not null
     order by lower(title)
      </querytext>
</fullquery>

<fullquery name="get_rels">
      <querytext>

    select arr.pretty_plural,
           art.rel_type as relation_type,
           ( select count(distinct gmm.member_id) from group_approved_member_map gmm where gmm.group_id = :group_id and gmm.rel_type = art.rel_type ) as member_count
      from acs_rel_types art,
           acs_rel_roles arr
     where art.rel_type in ( select distinct gmm.rel_type from group_approved_member_map gmm where gmm.group_id = :group_id )
       and art.role_two = arr.role

      </querytext>
</fullquery>

<fullquery name="contacts_select">      
      <querytext>
select contact__name(parties.party_id),
       parties.party_id,
       cr_revisions.revision_id,
       contact__name(parties.party_id,:name_order) as name,
       parties.email,
       ( select first_names from persons where person_id = party_id ) as first_names,
       ( select last_name from persons where person_id = party_id ) as last_name,
       ( select name from organizations where organization_id = party_id ) as organization
  from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and group_distinct_member_map.group_id = '11428599'
$search_clause
[template::list::page_where_clause -and -name "contacts" -key "party_id"]
[template::list::orderby_clause -orderby -name "contacts"]
      </querytext>
</fullquery>

<fullquery name="select_member_states">
      <querytext>

        select mr.member_state as state, 
               count(mr.rel_id) as num_contacts
        from   membership_rels mr, acs_rels r
        where  r.rel_id = mr.rel_id
          and  r.object_id_one = :group_id
          and  r.rel_type = 'membership_rel'
        group  by mr.member_state

      </querytext>
</fullquery>
 
</queryset>
