
/* *********************************
 * DuplicateFinder Class 
 * @description     This class uses the built in duplicate search feature of salesforce to identify
 *                  duplicates in a bulk manner
 *
 *                  Class should be run without sharing so that all records can be searched
 *
 *                  Class should implement the queueable interface so that it can iteratively process 
 *                  all the records in the organization
 *
 * copied from https://github.com/patrick-yan-sf/FindDuplicates/blob/master/src/classes/DuplicateFinder.cls
 */
public without sharing class FindDuplicates {

    private List<Datacloud.FindDuplicatesResult> results;
    public List<DuplicateRecordSet> existingDuplicateRecordSets = new List<DuplicateRecordSet>();
    public List<DuplicateRecordSet> newDuplicateRecordSets = new List<DuplicateRecordSet>();

    /*Query existing duplicates
    public FindDuplicates(List<SObject> objects) {
        results = Datacloud.FindDuplicates.findDuplicates(objects);
        //existingDuplicateRecordSets = FindDuplicatesSelector.selectDuplicateRecordSets(objects);

        for (Datacloud.FindDuplicatesResult result : results) {
            //One FindDuplicatesResult per object in list; methods:
            //List<Datacloud.DuplicateResult> getDuplicateResults()
            //List<Database.Error> getErrors()
            //Boolean isSuccess()

            for (Datacloud.DuplicateResult dupeResult : result.getDuplicateResults()) {
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

    /***
     * @description Determines if the SObject is a duplicate and if so, 
     * creates a DuplicateRecordSet for it if it does not exists already.
     */
    public findDuplicates(List<SObject> sObjects) {
        List<DuplicateSetInfo> duplicateSetInfos = new List<DuplicateSetInfo>();

        List<Datacloud.FindDuplicatesResult> results = getResults(sObjects);

        for (Integer i = 0, size = sObjects.size(); i < size; i++) {
        
            for (Datacloud.DuplicateResult dupeResult : results[i].getDuplicateResults()) {
        
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    if (matchResult.getSize() <= 0) {//not a duplicate based on this duplicate match rule
                        continue;
                    }
                    Id recordId = sObjects[i].Id;

                    DuplicateSetInfo dsi = findDuplicateSet(
                        recordId, 
                        dupeResult.getDuplicateRule(), 
                        duplicateSetInfos
                    );

                    dsi.addRecordItem(recordId);
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        dsi.addRecordItem((matchRecord.getRecord()).Id);
                    }
                }
            }
        }

        createRecords(duplicateSetInfos);
    }

    public List<Datacloud.FindDuplicatesResult> getResults(List<SObject> sObjects) {
        return Datacloud.FindDuplicates.findDuplicates(sObjects);
    }

    private DuplicateSetInfo findDuplicateSet(Id recordId, String duplicateRuleName, List<DuplicateSetInfo> duplicateSetInfos) {
        DuplicateSetInfo dsi;
        Boolean isFound = false;
        Id duplicateRuleId = FindDuplicatesSelector.duplicateRuleIdsByName.get(duplicateRuleName);

        for (DuplicateSetInfo info : duplicateSetInfos) {
            if (info.getDuplicateRuleId() == duplicateRuleId
                && info.hasRecordItem(recordId)
            ) {
                isFound = true;
                break;
            }
        }

        if (!isFound) {
            dsi = new DuplicateSetInfo(duplicateRuleId);
        }

        return dsi;
    }

    private void createRecords(List<DuplicateSetInfo> duplicateSetInfos) {
        List<DuplicateRecordSet> duplicateSets = new List<DuplicateRecordSet>();
        List<DuplicateRecordItem> recordItems = new List<DuplicateRecordItem>();

        for (DuplicateSetInfo info : duplicateSetInfos) {
            duplicateSets.add(info.getDuplicateSet());
        }
        insert duplicateSets;

        for (DuplicateSetInfo info : duplicateSetInfos) {
            recordItems.addAll(info.getRecordItems());
        }
        insert recordItems;
    }


    public class DuplicateSetInfo {
        private DuplicateRecordSet duplicateSet = new DuplicateRecordSet();
        private Map<Id, DuplicateRecordItem> recordItemsById = new Map<Id, DuplicateRecordItem>();

        public DuplicateSetInfo(Id duplicateRuleId) {
            duplicateSet.duplicateRuleId = duplicateRuleId;
        }

        public Id getDuplicateRuleId() {
            return duplicateSet.duplicateRuleId;
        }

        public DuplicateRecordSet getDuplicateSet() {
            return duplicateSet;
        }

        public Boolean hasRecordItem(Id recordId) {
            return recordItemsById.containsKey(recordId);
        }

        public void addRecordItem(Id recordId) {
            recordItemsById.put(
                recordId, 
                new DuplicateRecordItem(
                    RecordId = recordId
                )
            );
        }

        public List<DuplicateRecordItem> getRecordItems() {
            for (DuplicateRecordItem item : recordItemsById.values()) {
                item.DuplicateRecordSetId = duplicateSet.Id;
            }

            return recordItemsById.values();
        }
    }
}