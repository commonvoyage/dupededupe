public without sharing class FindDuplicates {
    public Map<String, DuplicateRule> duplicateRules {
        public get {
            if (duplicateRules == null) {
                duplicateRules = new Map<String, DuplicateRule>();
                
                List<DuplicateRule> dupeRules = [SELECT Id, DeveloperName FROM DuplicateRule];
                for (DuplicateRule dr : dupeRules) {
                    duplicateRules.put(dr.DeveloperName, dr);
                }
            }
            return duplicateRules;
        }
        private set;
    }

    private List<Datacloud.FindDuplicatesResult> results;
    public List<DuplicateRecordSet> existingDuplicateRecordSets = new List<DuplicateRecordSet>();
    public List<DuplicateRecordSet> newDuplicateRecordSets = new List<DuplicateRecordSet>();

    /*Query existing duplicates
    public FindDuplicates(List<SObject> objects) {
        results = Datacloud.FindDuplicates.findDuplicates(objects);
        //existingDuplicateRecordSets = FindDuplicatesSelector.selectDuplicateRecordSets(objects);

        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            //One FindDuplicatesResult per object in list; methods:
            //List<Datacloud.DuplicateResult> getDuplicateResults()
            //List<Database.Error> getErrors()
            //Boolean isSuccess()

            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                //One DuplicateResult per active Duplicate Rule for this object

                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    //one MatchResult per Matching Rule for the current Duplicate Rule

                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        //one MatchRecord per identified record for the current Matching Rule
                        System.debug('Duplicate Record: ' + matchRecord.getRecord());
                    }
                }
            }
        }
    }*/

/* *********************************
 * DuplicateFinder Class 
 * @description     This class uses the built in duplicate search feature of salesforce to identify
 *                  duplicates in a bulk manner
 *
 *                  Class should be run without sharing so that all records can be searched
 *
 *                  Class should implement the queueable interface so that it can iteratively process 
 *                  all the records in the organization
 */

//copied from https://github.com/patrick-yan-sf/FindDuplicates/blob/master/src/classes/DuplicateFinder.cls



    /*public List<DuplicateSetInfo> findAllDuplicateContacts() {
        List<Contact> contacts = [SELECT Id, Name, Email, Phone FROM Contact LIMIT 200];
        return findDuplicates(contacts);
    }*/

    public FindDuplicates(List<SObject> objects) {
        Set<String> currentDupIds = new Set<String>();

        List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(objects);

        List<DuplicateSetInfo> duplicateSets = new List<DuplicateSetInfo>();
        List<DuplicateRecordSet> parentRecords = new List<DuplicateRecordSet>(); 

        // Each record in the original list will result in a find duplicate result object
        Integer recordSearchSize = objects.size();

        for (Integer i = 0; i<recordSearchSize; i++) {
            String listRecordId = objects[i].Id;
            // skip if record is already in a previous duplicate Set
            if (currentDupIds.contains(listRecordId)) {
                continue;
            }

            Datacloud.FindDuplicatesResult findDupeResult = results[i];
        
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
        
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
        
                    // basically if it is a duplicate then create a set for it
                    if (matchResult.getSize() > 0) {
                        Boolean addToInsertList = false;
                        // Need to create one for the current record as well
                        System.debug('Found a match: ' + matchResult);
                        // need to add the duplicate record id to a list so that we do not try to create 
                        // another set for it
                        DuplicateSetInfo dsi = new DuplicateSetInfo();
                        // Also need to add the object that is currently being reviewed

                        DuplicateRecordSet duplicateSet = new DuplicateRecordSet();
                        duplicateSet.duplicateRuleId = (duplicateRules.get(dupeResult.getDuplicateRule())).Id;
                        dsi.duplicateSet = duplicateSet;

                        DuplicateRecordItem recordItem = new DuplicateRecordItem(
                            RecordId = listRecordId
                        );
                        dsi.duplicateItems.add(recordItem);

                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            DuplicateRecordItem duplicateItem = new DuplicateRecordItem(
                                RecordId = (matchRecord.getRecord()).Id
                            );

                            currentDupIds.add(duplicateItem.RecordId);
                            dsi.duplicateItems.add(duplicateItem);
                            addToInsertList = true;
                        }

                        if (addToInsertList) {
                            parentRecords.add(duplicateSet);
                            duplicateSets.add(dsi);
                        }
                    }
                }
            }
        }


        // save the top level duplicate set first
        //THIS IS CREATING DUPLICATE DUPLICATE RECORD SETS LOL
        if (!parentRecords.isEmpty()) {
            System.debug('duplicateSets ' + duplicateSets);
            System.debug('parentRecords ' + parentRecords);
            insert parentRecords;

            List<DuplicateRecordItem> childRecords = new List<DuplicateRecordItem>();
            for (DuplicateSetInfo dsi : duplicateSets) {
                dsi.prepareForInsert();
                childRecords.addAll(dsi.duplicateItems);
            }

            System.debug('childRecords ' + childRecords);
            insert childRecords;
        }
    }

    public class DuplicateSetInfo {
        public DuplicateRecordSet duplicateSet;
        public List<DuplicateRecordItem> duplicateItems;

        public DuplicateSetInfo() {
            duplicateItems = new List<DuplicateRecordItem>();
        }

        public void prepareForInsert() {
            for (DuplicateRecordItem recordItem : duplicateItems) {
                recordItem.DuplicateRecordSetId = duplicateSet.Id;
            }
        }
    }
}