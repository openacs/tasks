<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.3</version></rdbms>

<fullquery name="process_query">
    <querytext>
        SELECT p.process_id,
               p.one_line,
               p.description,
               p.party_id,
               to_char(p.creation_date,'YYYY-MM-DD') as creation_date_ansi
        FROM   pm_process p
        ORDER BY p.one_line        
    </querytext>
</fullquery>

</queryset>
