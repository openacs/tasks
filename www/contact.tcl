ad_page_contract {

    Main view page for tasks.

    @author jader@bread.com
    @creation-date 2003-12-03
    @cvs-id $Id$

    @return title Page title.
    @return context Context bar.
    @return tasks Multirow data set of tasks

    @param mine_p is used to make the default be the user, but
    still allow people to view everyone.

} {
    {object_id ""}
} -properties {
}

set package_id [ad_conn package_id]

#ad_return_error object $object_id
