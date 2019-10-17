@isTest
private class FindDuplicatesTest {
    @isTest
    private static void FindDuplicatesTest() {
    }

    @isTest
    private static void insertDuplicateRecordSet() { 
        List<Account> accounts = new List<Account>();
        // you need at least one active duplicate rule
        DuplicateRule rule = [SELECT Id FROM DuplicateRule WHERE SObjectType = 'Account' AND IsActive = true LIMIT 1];

        DuplicateRecordSet drs = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );

        insert drs;

        List<DuplicateRecordItem> items = new List<DuplicateRecordItem>();

        for (Account acct : accounts) {
            items.add(new DuplicateRecordItem(
                duplicateRecordSetId = drs.id,
                recordId = acct.id
            ));
        }
        insert items;
    }

}
/*
Database.DMLOptions dmlOptions = new Database.DMLOptions();
dmlOptions.DuplicateRuleHeader.allowSave = true;

Database.insert(new Contact(LastName='DeDupe', FirstName='Dupe', Email='dupededupe@gmail.com'), dmlOptions);



6 Tips for Duplicate Management with Apex
By: David Cheng | 1.15.19

As we launch into a new year, maybe one of your resolutions is to cultivate better deduplication habits. 
Sometimes it’s not enough to use a simple deduplication app or follow standard data cleanliness best practices,
 like the ones we gave here.

Today, we wanted to go deeper and share some advanced tips for the Salesforce Developer who knows Apex 
and is ready to take this to the next level.

Let’s dive in.

 

Why use Apex for duplicate management?
If you've built a custom Visualforce online form or other Apex integration that involves contacts, 
you've probably run into limitations with duplicate detection, especially since SOQL doesn't have 
fuzzy search capability.

Now you can use the standard Salesforce duplicate rules in Apex. Benefits include:

Fuzzy matching on contact's first name
Matching rules can be configured by system administrator in Setup instead of being hardcoded in Apex
Here are my tips for Duplicate Management with Apex.

 

#1: How to use findDuplicates
Duplicate results are returned in a complex hierarchy of objects.

findDuplicates() returns a list of Datacloud.FindDuplicatesResult objects where each element 
corresponds to the element in the list that was passed in. So if a contact list was passed in, 
then fdresults[0] corresponds to contacts[0], fdresults[1] to contacts[1], etc.

findDuplicatesResult has a success property, but this is not related to active/inactive rules. 
It appears to be used for other types of errors which are not described in the documentation.

Each findDuplicatesResult object contains a list of DuplicateResult objects.  
Each DuplicateResult object corresponds to an active duplicate rule for the object.

Each DuplicateResult record contains a MatchResults object.

Finally, the MatchResults object contains a list of MatchRecord objects.  
In MatchRecord, the record contains the actual matched Object record.

 

#2: Be aware what fields are returned in the MatchRecord
findDuplicates returns only the fields specified in the primary CompactLayout 
associated with the target object. There is no way to change this. 
Thus you must execute a separate query to get fields that are not in the CompactLayout.

 

#3: How to deal with multiple Duplicate Rules for an Object
This is complex since you get can get multiple lists of MatchRecords returned, 
especially if the lists don't have the same records and/or they are not in the same order. 
You will have to decide how to pick the "winning" match from the different lists which will 
depend on your specific set of duplicate rules.

 

#4: How to detect if Duplicate Rules are active
There is no graceful way to detect if there are any active Duplicate Rules. 
The only way is to execute the Datacloud.FindDuplicates.findDuplicates() method.  
If there are no active rules, then an exception will be thrown and you must catch it.

The exception message is "System.HandledException: No active duplicate rules are defined for the 
[objname] object type".

 

#5: How to override Duplicate Management Rules
If you need to override all duplicate management rules, set the allowSave property 
in the DmlOptions.DuplicateRuleHeader class.

Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;

See more about this in the documentation here.

 

#6: How a Site Guest User can bypass Sharing Rules
Site Guest User can use duplicate process, but the duplicate rules must be set to 
Bypass Sharing in order for all Contacts to be available for matching.

 

Examples of findDuplicates() with various Rules
There are two active Contact duplicate rules.

Rule 1 checks for first name fuzzy / last name / email.
Rule 2 checks for first name fuzzy / last name / zip code.
 

There are three existing contacts

Name = John Doe, Email = jdoe@test.com, Zip Code = 12345
Name = John Doe, Email = jd@test.com, Zip Code = 12345.
Name = Jack Doe, Email = jack@test.com, Zip Code = 12345.
 

There are two contacts in the search list

Name = Jack Doe, Email = jack@test.com, Zip Code = 12345.
Name = John Doe, Email = somebody@test.com, Zip Code = 99999.
 

Datacloud.FindDuplicates.findDuplicates will return a list of two elements.

fdResults[0] will contain two lists of DuplicateResults

fdResults[0].dupResults[0] is Rule 1.  There will be 1 MatchResult.

fdResults[0].dupResults[1] is Rule 2.  There will be 3 MatchResults.

 

fdResults[1] will contain two lists of DuplicateResults

fdResults[1].dupResults[0] is Rule 1.  There will be 0 MatchResults.

fdResults[1].dupResults[1] is Rule 2.  There will be 0 MatchResults.

 

public static List<Contact> findContacts(List<Contact> cons) {
	List<Contact> foundContacts = new List<Contact>();
	List<Datacloud.FindDuplicatesResult> results;
	try {
		results = Datacloud.FindDuplicates.findDuplicates(cons);
	} catch (Exception ex) {
		// FYI if there are no active rules for an object, then the exception is
		// System.HandledException: No active duplicate rules are defined for the [objname] object type
		return null;
	}

	// Loop the original contacts
	for (Integer i = 0; i < cons.size(); i++) {
		Contact foundCon = null;
		// Find the first duplicate result with a match result, then use the first match record.
		for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
			if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
				foundCon = (Contact) dr.getMatchResults()[0].getMatchRecords()[0].getRecord();
				break;
			}
		}
		foundContacts.add(foundCon);
	}

	return foundContacts;
}


Gotcha: Phone number matching is exact
Beware of this gotcha: phone number matching is exact in the duplicate rules, 
so 2025551212 does not match (202) 555-1212.  
If you are submitting new contacts via online forms or data import, 
be sure to format phone numbers properly if your duplicate rules match on phone number.
*/