public without sharing class FindDuplicates {
    private List<Datacloud.FindDuplicatesResult> results;
    public List<DuplicateRecordSet> existingDuplicateRecordSets = new List<DuplicateRecordSet>();
    public List<DuplicateRecordSet> newDuplicateRecordSets = new List<DuplicateRecordSet>();

    /*Query existing duplicates*/
    public FindDuplicates(List<SObject> objects) {
        results = Datacloud.FindDuplicates.findDuplicates(objects);
        //existingDuplicateRecordSets = FindDuplicatesSelector.selectDuplicateRecordSets(objects);

        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            /*
            One FindDuplicatesResult per object in list; methods:
            List<Datacloud.DuplicateResult> getDuplicateResults()
            List<Database.Error> getErrors()
            Boolean isSuccess()
            */

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
    }
}