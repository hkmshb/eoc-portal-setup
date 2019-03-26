select
	(select count(*) from afp_case_based where "DateReceived" is not null) "afp_cb",
	(select count(*) from redo_data where "RevisitID" is not null) "redo",
	(select count(*) from tallysheet_data where "Tally ID" is not null) "tally",
	(select count(*) from vaccine_data where "State" is not null) "vaccine"
	;


drop table afp_case_based cascade;
drop table redo_data cascade;
drop table tallysheet_data cascade;
drop table vaccine_data cascade;