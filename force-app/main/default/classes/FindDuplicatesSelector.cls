public with sharing class FindDuplicatesSelector {

/*
    SELECT Id, DuplicateRecordSetId, Name, RecordId FROM DuplicateRecordItem

    SELECT DuplicateRuleId, LastReferencedDate, LastViewedDate, Name, RecordCount, ParentId, SobjectType FROM DuplicateRecordSet
*/
    public List<DuplicateRecordSet> selectDuplicateRecordSets (List<SObject> objects) {
        return [
            SELECT 
                Id,
                DuplicateRuleId, 
                Name, 
                RecordCount,
                    (SELECT Id, RecordId FROM DuplicateRecordItems)
//The below fields should exist but are hidden unless your org is Performance or Unlimited Edition :'/
                //ParentId, 
                //SobjectType 
            FROM 
                DuplicateRecordSet
            //WHERE
                //ParentId IN :objects
        ];
    }
}
/*
List<DuplicateRecordSet> recordSets = 
    [SELECT 
                DuplicateRuleId, 
                Name, 
                RecordCount,
              (SELECT recordId FROM DuplicateRecordItems)
            FROM 
                DuplicateRecordSet];
for (DuplicateRecordSet drs : recordSets) {
    system.debug(drs);
    for (DuplicateRecordItem item : drs.DuplicateRecordItems) {
        system.debug(item);
    }
}
*/