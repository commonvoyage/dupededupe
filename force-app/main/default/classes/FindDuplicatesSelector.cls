public with sharing class FindDuplicatesSelector {

/*
    SELECT Id, DuplicateRecordSetId, Name, RecordId FROM DuplicateRecordItem

    SELECT DuplicateRuleId, LastReferencedDate, LastViewedDate, Name, RecordCount, ParentId, SobjectType FROM DuplicateRecordSet
*/
    public List<DuplicateRecordSet> selectDuplicateRecordSets(List<SObject> objects) {
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

    public static List<DuplicateRecordItem> selectDuplicateRecordItems(List<SObject> objects) {
        return [
            SELECT
                Id,
                RecordId,
                DuplicateRecordSetId,
                DuplicateRecordSet.Id,
                DuplicateRecordSet.DuplicateRuleId,
                DuplicateRecordSet.Name,
                DuplicateRecordSet.RecordCount
            FROM DuplicateRecordItem
            WHERE RecordId IN :objects
        ];
    }

    public static Map<String, Id> duplicateRuleIdsByName {
        public get {
            if (duplicateRuleIdsByName == null) {
                duplicateRuleIdsByName = new Map<String, Id>();
                
                List<DuplicateRule> dupeRules = [SELECT Id, DeveloperName FROM DuplicateRule];
                for (DuplicateRule dr : dupeRules) {
                    duplicateRuleIdsByName.put(dr.DeveloperName, dr.id);
                }
            }
            return duplicateRuleIdsByName;
        }
        private set;
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