testbranch ()
{
	local test=""

	local month=`date +%b | tr '[A-Z]' '[a-z]'`
	local year=`date +%y`
	test=test_$month$year

	echo "$test"
}

testbranch
