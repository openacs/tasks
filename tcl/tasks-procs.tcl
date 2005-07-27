ad_library {

    Tasks Library

    @creation-date 2003-12-18
    @author Matthew Geddert <openacs@geddert.com>
    @cvs-id $Id$

}

namespace eval tasks {}


ad_proc -public tasks::project_id {
    {-package_id ""}
} {
    Returns this tasks instance project_id
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    set project_id [db_string get_project_id {
        select pm_projectsx.item_id
          from pm_projectsx,
               cr_folders cf
         where pm_projectsx.parent_id = cf.folder_id
           and cf.package_id = :package_id
    } -default {}]
    if { [string is false [exists_and_not_null project_id]] } {
	tasks::initialize -package_id $package_id
	set project_id [tasks::project_id -package_id $package_id]
    }
    return $project_id
}

ad_proc -public tasks::initialize {
    {-package_id ""}
} {
    Returns this tasks instance project_id
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    if { [string is false [db_0or1row project_exists_p { select 1 from cr_folders where package_id = :package_id and label = 'Projects' }]] } {
	pm::project::new -project_name "Tasks Instance $package_id" \
	    -status_id "1" \
	    -organization_id "" \
	    -creation_user [ad_conn user_id] \
	    -creation_ip [ad_conn peeraddr] \
	    -ongoing_p "t" \
	    -package_id $package_id
    }
}


