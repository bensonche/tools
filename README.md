Intranet-tools
==============
This is a collection of bash scripts I use often during Intranet development.

-bashrc.bash
  +This is a copy of my .bashrc file, with aliases to the tools in this repo.

-check_branch.bash
  +This script is ran against any branch that's scheduled to be merged into release. It will update the branch with release if necessary.

-create_db_script.bash
  +This script is used to review and create the SQL script to update the database with what is in the repo.

-push_to_test.bash
  +This script will update your test branch, merge your current branch into test, and push the test branch.

-setup.bash
  +This is a short script to overwrite the .bashrc file with the bashrc in this repo.

-tag.bash
  +This is used to tag the master branch with the given release number.
