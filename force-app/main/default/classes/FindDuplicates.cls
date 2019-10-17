
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
     * @description Finds duplicates and creates Schema duplicate record SObjects.
     * @param sObjects SObjects (Account, Contact, Lead) that can have duplicate rules created for
     * @return void
     */
    public void execute(List<SObject> sObjects) {
        List<DuplicateSetInfo> duplicateSetInfos = getDuplicateSets(sObjects);
        List<Datacloud.FindDuplicatesResult> results = getResults(sObjects);

        for (Integer i = 0, size = sObjects.size(); i < size; i++) {
        
            for (Datacloud.DuplicateResult dupeResult : results[i].getDuplicateResults()) {

                //TODO need to take order into account since Duplicate Rules 
                //will return all Duplicate Rules matching results
        
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    if (matchResult.getSize() <= 0) {//not a duplicate based on this duplicate match rule
                        continue;
                    }

                    Id recordId = sObjects[i].Id;

                    DuplicateSetInfo dsi = getDuplicateSet(
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

    /***
     * @description Retrieves existing DuplicateRecordSet/Item for specified SObjects
     * @param sObjects SObjects that can have duplicate rule created for
     * @return List<DuplicateSetInfo> Representation of the DuplicateRecordSet/Item information
     */
    public List<DuplicateSetInfo> getDuplicateSets(List<SObject> sObjects) {
        Map<Id, DuplicateSetInfo> duplicateSetInfoBySetId = new Map<Id, DuplicateSetInfo>();

        for (DuplicateRecordItem recordItem : FindDuplicatesSelector.selectDuplicateRecordItems(SObjects)) {
            if (!duplicateSetInfoBySetId.containsKey(recordItem.DuplicateRecordSetId)) {
                duplicateSetInfoBySetId.put(
                    recordItem.DuplicateRecordSetId, 
                    new DuplicateSetInfo(recordItem.DuplicateRecordSet)
                );
            }
            DuplicateSetInfo dsi = duplicateSetInfoBySetId.get(recordItem.DuplicateRecordSetId);

            dsi.addRecordItem(recordItem);
        }

        return duplicateSetInfoBySetId.values();
    }

    /***
     * @description Finds duplicates based on the Duplicate Rules
     * @param sObjects SObjects to find duplicates for
     * @return List<Datacloud.FindDuplicatesResult> Duplicate search results
     */
    public List<Datacloud.FindDuplicatesResult> getResults(List<SObject> sObjects) {
        return Datacloud.FindDuplicates.findDuplicates(sObjects);
    }

    /***
     * @description Determines the DuplicateRecordSet for the record
     * @param recordId SObject Id
     * @param duplicateRuleName Duplicate Rule Name
     * @param duplicateSetInfos Representation of the DuplicateRecordSet/Item information
     * @return DuplicateSetInfo
     */
    private DuplicateSetInfo getDuplicateSet(Id recordId, String duplicateRuleName, List<DuplicateSetInfo> duplicateSetInfos) { 
        Id duplicateRuleId = FindDuplicatesSelector.duplicateRuleIdsByName.get(duplicateRuleName);
        DuplicateSetInfo dsi;

        for (DuplicateSetInfo info : duplicateSetInfos) {
            if (info.getDuplicateRuleId() == duplicateRuleId
                && info.hasRecordItem(recordId)
            ) {
                dsi = info;
                break;
            }
        }

        if (dsi == null) {
            dsi = new DuplicateSetInfo(duplicateRuleId);
            duplicateSetInfos.add(dsi);
        }

        return dsi;
    }

    /***
     * @description Creates DuplicateRecordSet/Item records
     * @param duplicateSetInfos Representation of the DuplicateRecordSet/Item information
     * @return void
     */
    private void createRecords(List<DuplicateSetInfo> duplicateSetInfos) {
        List<DuplicateRecordSet> duplicateSets = new List<DuplicateRecordSet>();
        List<DuplicateRecordItem> recordItems = new List<DuplicateRecordItem>();

        for (DuplicateSetInfo info : duplicateSetInfos) {
            if (!info.hasId()) {
                duplicateSets.add(info.getDuplicateSet());
            }
        }
        insert duplicateSets;

        for (DuplicateSetInfo info : duplicateSetInfos) {
            recordItems.addAll(info.getNewRecordItems());
        }
        insert recordItems;
    }


    /***
     * @description Representation of the DuplicateRecordSet/Item information
     */
    public class DuplicateSetInfo {
        private DuplicateRecordSet duplicateSet = new DuplicateRecordSet();
        private Map<Id, DuplicateRecordItem> recordItemsById = new Map<Id, DuplicateRecordItem>();

        public DuplicateSetInfo(Id duplicateRuleId) {
            duplicateSet.duplicateRuleId = duplicateRuleId;
        }

        public DuplicateSetInfo(DuplicateRecordSet duplicateSet) {
            this.duplicateSet = duplicateSet;
        }

        public Id getDuplicateRuleId() {
            return duplicateSet.duplicateRuleId;
        }

        public DuplicateRecordSet getDuplicateSet() {
            return duplicateSet;
        }

        public Boolean hasId() {
            return duplicateSet.Id != null;
        }

        public Boolean hasRecordItem(Id recordId) {
            return recordItemsById.containsKey(recordId);
        }


        public void addRecordItem(Id recordId) {
            if (!recordItemsById.containsKey(recordId)) {
                recordItemsById.put(
                    recordId, 
                    new DuplicateRecordItem(RecordId = recordId)
                );
            }
        }

        public void addRecordItem(DuplicateRecordItem recordItem) {
            recordItemsById.put(recordItem.RecordId, recordItem);
        }

        public List<DuplicateRecordItem> getNewRecordItems() {
            List<DuplicateRecordItem> newRecordItems = new List<DuplicateRecordItem>();

            for (DuplicateRecordItem item : recordItemsById.values()) {
                if (item.DuplicateRecordSetId == null) {
                    item.DuplicateRecordSetId = duplicateSet.Id;
                }

                if (item.Id == null) {
                    newRecordItems.add(item);
                }
            }

            return newRecordItems;
        }
    }
}