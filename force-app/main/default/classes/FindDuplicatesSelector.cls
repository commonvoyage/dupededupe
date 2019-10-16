public with sharing class FindDuplicatesSelector {

/*
    SELECT Id, DuplicateRecordSetId, Name, RecordId FROM DuplicateRecordItem

    SELECT DuplicateRuleId, LastReferencedDate, LastViewedDate, Name, RecordCount, ParentId, SobjectType FROM DuplicateRecordSet
*/
    public List<DuplicateRecordSet> selectDuplicateRecordSets (List<SObject> objects) {
        return [
            SELECT 
                DuplicateRuleId, 
                Name, 
                RecordCount, 
                ParentId, 
                SobjectType 
            FROM 
                DuplicateRecordSet
            WHERE
                ParentId IN :objects
        ];
    }
}
